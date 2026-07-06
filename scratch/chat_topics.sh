#!/usr/bin/env bash
# Generate diverse conversation topics using an LLM.
# Secret sauce — kept separate from the chat command.
#
# Usage:
#   bash scratch/chat_topics.sh
#   API_URL=http://... MODEL=... TOPICS=100 bash scratch/chat_topics.sh

set -euo pipefail

API_URL="${API_URL:-http://192.168.1.66:13305/v1}"
MODEL="${MODEL:-Qwen3.5-4B-GGUF}"
TOPICS="${TOPICS:-50}"
OUTPUT="${OUTPUT:-scratch/chat_topics.txt}"

cd "$(dirname "$0")/.."

echo "Generating $TOPICS topics using $MODEL at $API_URL..."
echo

uv run python3 -c "
import json, os, sys
from openai import OpenAI
import httpx

client = OpenAI(
    base_url='$API_URL',
    api_key='dummy',
    http_client=httpx.Client(
        limits=httpx.Limits(max_connections=100, max_keepalive_connections=10),
    ),
)

response = client.chat.completions.create(
    model='$MODEL',
    messages=[{
        'role': 'system',
        'content': (
            'You are a creative topic curator. '
            'Generate exactly $TOPICS diverse conversation topics across these categories: '
            'technology, philosophy, daily life, creative writing, science, ethics, humor, '
            'history, art, futurism, relationships, education, travel, food, nature, sports, '
            'music, books, movies, gaming, health, business, psychology, society, space, mythology. '
            'Output exactly one topic per line. No numbering, no markdown, no commentary. '
            'Each topic should be a short phrase that could seed an engaging multi-turn conversation. '
            'Avoid generic topics — make them specific and thought-provoking.'
        ),
    }],
    max_tokens=2048,
    temperature=0.9,
)

topics = response.choices[0].message.content.strip().split('\n')
topics = [t.strip().lstrip('0123456789. -') for t in topics if t.strip()]
topics = topics[:$TOPICS]

os.makedirs(os.path.dirname('$OUTPUT'), exist_ok=True)
with open('$OUTPUT', 'w') as f:
    for t in topics:
        f.write(t + '\n')

print(f'Saved {len(topics)} topics to $OUTPUT')
" 2>&1

echo
echo "Done. Topics saved to $OUTPUT"
