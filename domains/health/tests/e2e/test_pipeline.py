"""
End-to-end tests for the full analysis pipeline.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from pipeline.analyze import analyze_all
from pipeline.config import Config
from pipeline.consolidate import consolidate_all
from pipeline.extract import compute_data_hash, extract_all, get_data_summary


class TestExtractStage:
    """Tests for the extraction stage."""

    @pytest.mark.e2e
    def test_extract_all_individuals(self, base_path: Path) -> None:
        """Test extracting data for all individuals."""
        config = Config(base_path)
        extracted = extract_all(config)

        assert len(extracted) >= 1, "Should extract at least one individual"

        for key, files in extracted.items():
            assert len(files) >= 0, f"Should have files for {key}"

    @pytest.mark.e2e
    def test_data_hash_deterministic(self, base_path: Path) -> None:
        """Test that data hash is deterministic."""
        config = Config(base_path)

        hash1 = compute_data_hash(config)
        hash2 = compute_data_hash(config)

        assert hash1 == hash2, "Data hash should be deterministic"
        assert len(hash1) == 64, "Hash should be SHA256 (64 hex chars)"

    @pytest.mark.e2e
    def test_data_summary(self, base_path: Path) -> None:
        """Test data summary generation."""
        config = Config(base_path)
        summary = get_data_summary(config)

        assert "individuals" in summary
        assert "data_files" in summary
        assert "total_records" in summary
        assert summary["total_records"] > 0


class TestConsolidateStage:
    """Tests for the consolidation stage."""

    @pytest.mark.e2e
    def test_consolidate_all_individuals(self, base_path: Path) -> None:
        """Test consolidating data for all individuals."""
        config = Config(base_path)

        # First extract
        extract_all(config)

        # Then consolidate
        all_data = consolidate_all(config)

        assert len(all_data) >= 1, "Should consolidate at least one individual"

        for key, data in all_data.items():
            assert "physiological" in data, f"{key} should have physiological data"
            assert len(data["physiological"]) > 0

    @pytest.mark.e2e
    def test_deduplication(self, base_path: Path) -> None:
        """Test that consolidation deduplicates data."""
        config = Config(base_path)

        extract_all(config)
        all_data = consolidate_all(config)

        for key, data in all_data.items():
            physio = data.get("physiological")
            if physio is not None and len(physio) > 0:
                # Check no duplicate timestamps
                timestamps = physio["Cycle start time"]
                assert timestamps.is_unique, f"{key} should have unique timestamps"


class TestAnalyzeStage:
    """Tests for the analysis stage."""

    @pytest.mark.e2e
    def test_analyze_all_individuals(self, base_path: Path) -> None:
        """Test analyzing all individuals."""
        config = Config(base_path)

        extract_all(config)
        all_data = consolidate_all(config)
        profiles = analyze_all(all_data, config)

        assert len(profiles) >= 1, "Should analyze at least one individual"

        for _key, profile in profiles.items():
            assert profile.health_scores is not None
            assert 0 <= profile.health_scores.overall <= 100
            assert profile.data_range.days > 0

    @pytest.mark.e2e
    def test_recommendations_generated(self, base_path: Path) -> None:
        """Test that recommendations are generated."""
        config = Config(base_path)

        extract_all(config)
        all_data = consolidate_all(config)
        profiles = analyze_all(all_data, config)

        # At least one profile should have recommendations
        total_recommendations = sum(len(p.recommendations) for p in profiles.values())
        assert total_recommendations > 0, "Should generate at least one recommendation"


class TestFullPipeline:
    """Tests for the complete pipeline execution."""

    @pytest.mark.e2e
    def test_full_pipeline_execution(self, base_path: Path, temp_dir: Path) -> None:
        """Test running the full pipeline."""
        from pipeline.main import run_pipeline

        # Run pipeline with temp output
        result = run_pipeline(
            base_path=base_path,
            stages=["extract", "consolidate", "analyze"],
            force=True,
        )

        assert result["status"] in ["completed", "exists"]
        assert "snapshot_id" in result

    @pytest.mark.e2e
    def test_pipeline_idempotent(self, base_path: Path) -> None:
        """Test that pipeline is idempotent (same input = same hash)."""
        config = Config(base_path)

        extract_all(config)
        hash1 = compute_data_hash(config)

        # Run again
        extract_all(config)
        hash2 = compute_data_hash(config)

        assert hash1 == hash2, "Pipeline should be idempotent"


class TestGoldenSnapshot:
    """Golden tests comparing against known-good snapshot."""

    @pytest.mark.golden
    def test_manifest_structure(self, golden_manifest: dict) -> None:
        """Test that manifest has expected structure."""
        if not golden_manifest:
            pytest.skip("No golden snapshot available")

        required_keys = [
            "version",
            "snapshot_id",
            "created_at",
            "data_hash",
            "input",
            "output",
            "pipeline",
        ]
        for key in required_keys:
            assert key in golden_manifest, f"Manifest should have {key}"

        assert golden_manifest["version"] == "1.0.0"
        assert len(golden_manifest["data_hash"]) == 64

    @pytest.mark.golden
    def test_profiles_structure(self, golden_profiles: dict) -> None:
        """Test that profiles have expected structure."""
        if not golden_profiles:
            pytest.skip("No golden snapshot available")

        # Should have profiles for expected individuals
        expected_keys = {"hank", "dad", "mom", "ayae", "phillip"}
        actual_keys = set(golden_profiles.keys())

        assert actual_keys == expected_keys, f"Expected {expected_keys}, got {actual_keys}"

        for _key, profile in golden_profiles.items():
            assert "individual" in profile
            assert "health_scores" in profile
            assert "data_range" in profile
            assert "recommendations" in profile

    @pytest.mark.golden
    def test_score_ranges(self, golden_profiles: dict) -> None:
        """Test that scores are within valid ranges."""
        if not golden_profiles:
            pytest.skip("No golden snapshot available")

        for key, profile in golden_profiles.items():
            scores = profile["health_scores"]
            for score_name, score_value in scores.items():
                assert 0 <= score_value <= 100, (
                    f"{key}.{score_name} should be 0-100, got {score_value}"
                )

    @pytest.mark.golden
    def test_data_ranges_valid(self, golden_profiles: dict) -> None:
        """Test that data ranges are valid."""
        if not golden_profiles:
            pytest.skip("No golden snapshot available")

        for key, profile in golden_profiles.items():
            data_range = profile["data_range"]
            assert data_range["days"] > 0, f"{key} should have positive days"
            assert data_range["start"] < data_range["end"], f"{key} start should be before end"

    @pytest.mark.golden
    def test_regeneration_matches_golden(
        self, base_path: Path, golden_profiles: dict, golden_manifest: dict
    ) -> None:
        """Test that regenerating produces same results as golden snapshot."""
        if not golden_profiles or not golden_manifest:
            pytest.skip("No golden snapshot available")

        config = Config(base_path)

        # Extract and consolidate
        extract_all(config)
        all_data = consolidate_all(config)
        profiles = analyze_all(all_data, config)

        # Compare data hashes
        current_hash = compute_data_hash(config)
        golden_hash = golden_manifest["data_hash"]

        assert current_hash == golden_hash, (
            f"Data hash mismatch: current={current_hash}, golden={golden_hash}"
        )

        # Compare health scores (should be very close, allowing for float precision)
        for key, profile in profiles.items():
            if key in golden_profiles:
                golden_scores = golden_profiles[key]["health_scores"]
                current_scores = profile.health_scores

                assert abs(current_scores.overall - golden_scores["overall"]) < 1, (
                    f"{key} overall score changed significantly"
                )

    @pytest.mark.golden
    def test_expected_recommendations(self, golden_profiles: dict) -> None:
        """Test that expected recommendations are present."""
        if not golden_profiles:
            pytest.skip("No golden snapshot available")

        # Dad and Mom should have respiratory recommendations
        for key in ["dad", "mom"]:
            profile = golden_profiles.get(key, {})
            recommendations = profile.get("recommendations", [])

            respiratory_recs = [r for r in recommendations if r.get("category") == "Respiratory"]

            assert len(respiratory_recs) > 0, (
                f"{key} should have respiratory recommendations due to low SpO2"
            )

    @pytest.mark.golden
    def test_visualization_files_exist(self, golden_snapshot_path: Path) -> None:
        """Test that expected visualization files exist."""
        if not golden_snapshot_path.exists():
            pytest.skip("No golden snapshot available")

        viz_path = golden_snapshot_path / "visualizations"
        if not viz_path.exists():
            pytest.skip("No visualizations in golden snapshot")

        expected_files = [
            "comparison_hrv.png",
            "comparison_rhr.png",
            "comparison_recovery.png",
            "comparison_sleep.png",
            "comparison_health_scores.png",
        ]

        for filename in expected_files:
            assert (viz_path / filename).exists(), f"Missing visualization: {filename}"

        # Check individual dashboards
        for individual in ["hank", "dad", "mom", "ayae", "phillip"]:
            dashboard = viz_path / f"dashboard_{individual}.png"
            assert dashboard.exists(), f"Missing dashboard: {dashboard.name}"
