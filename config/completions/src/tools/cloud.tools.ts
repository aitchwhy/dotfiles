/**
 * Cloud Platform CLI Tools
 * AWS, Azure, Google Cloud
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const cloudTools: readonly CliTool[] = [
  nixTool("awscli2", "aws", "cloud", "awscli2", "AWS CLI v2"),
  nixTool("azure-cli", "az", "cloud", "azure-cli", "Azure CLI"),
  nixTool("google-cloud-sdk", "gcloud", "cloud", "google-cloud-sdk", "Google Cloud SDK"),
] as const;
