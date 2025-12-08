/**
 * LiveKit Agents Skill Definition
 *
 * Python voice agent patterns with LiveKit.
 * Migrated from: config/claude-code/skills/livekit-agents/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const livekitAgentsSkill: SystemSkill = {
  name: 'livekit-agents' as SystemSkill['name'],
  description:
    'LiveKit Agents patterns for Python voice agents including STT/TTS integration and async patterns. Use when working on the voice agent.',
  allowedTools: ['Read', 'Write', 'Bash(python:*)', 'Bash(uv:*)'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Agent Structure',
      patterns: [
        {
          title: 'Basic Voice Agent',
          annotation: 'do',
          language: 'python',
          code: `from livekit.agents import Agent, AgentContext, JobContext, WorkerOptions, cli
from livekit.agents.llm import openai
from livekit.agents.stt import deepgram
from livekit.agents.tts import cartesia

class VoiceAgent(Agent):
    def __init__(self):
        super().__init__()
        self.stt = deepgram.STT()
        self.llm = openai.LLM(model="gpt-4")
        self.tts = cartesia.TTS()

    async def on_transcript(self, ctx: AgentContext, text: str):
        response = await self.llm.generate(text)
        await ctx.say(response, tts=self.tts)

async def entrypoint(ctx: JobContext):
    agent = VoiceAgent()
    await agent.start(ctx)

if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))`,
        },
      ],
    },
    {
      title: 'Async Patterns',
      patterns: [
        {
          title: 'Parallel Operations',
          annotation: 'do',
          language: 'python',
          code: `import asyncio

# Always use async/await
async def process_audio(audio_frame: AudioFrame) -> str:
    result = await stt.transcribe(audio_frame)
    return result.text

# Use asyncio.gather for parallel ops
results = await asyncio.gather(
    fetch_user(user_id),
    fetch_history(session_id),
)

# Use asyncio.create_task for background work
task = asyncio.create_task(log_analytics(event))`,
        },
      ],
    },
    {
      title: 'Environment Setup',
      patterns: [
        {
          title: 'UV Commands',
          annotation: 'info',
          language: 'bash',
          code: `cd apps/agent
uv sync                        # Install dependencies
uv run python -m src.main dev  # Run locally

# Required environment variables
export LIVEKIT_URL="wss://..."
export DEEPGRAM_API_KEY="..."
export OPENAI_API_KEY="..."`,
        },
      ],
    },
    {
      title: 'Error Handling',
      patterns: [
        {
          title: 'Agent Error Handling',
          annotation: 'do',
          language: 'python',
          code: `from livekit.agents import AgentError

try:
    result = await risky_operation()
except AgentError as e:
    logger.error(f"Agent error: {e}")
    await ctx.say("I'm sorry, something went wrong.")`,
        },
      ],
    },
  ],
}
