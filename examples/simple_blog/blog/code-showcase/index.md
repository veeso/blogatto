---
title: Syntax Highlighting Showcase
slug: code-showcase
date: 2025-01-25 00:00:00
description: A showcase of syntax highlighting across different programming languages
---

# Syntax Highlighting Showcase

Blogatto supports build-time syntax highlighting powered by [smalto](https://github.com/veeso/smalto). Code blocks are tokenized and rendered as styled HTML elements at build time, so no JavaScript is required on the client.

## Gleam

```gleam
import gleam/io
import gleam/list
import gleam/string

pub type Animal {
  Cat(name: String, lives: Int)
  Dog(name: String, is_good: Bool)
}

pub fn greet(animal: Animal) -> String {
  case animal {
    Cat(name, ..) -> "Hello, " <> name <> "!"
    Dog(name, is_good) ->
      case is_good {
        True -> name <> " is a good dog!"
        False -> name <> " is still a good dog!"
      }
  }
}

pub fn main() {
  let pets = [Cat("Whiskers", 9), Dog("Rex", True)]
  pets
  |> list.map(greet)
  |> list.each(io.println)
}
```

## Rust

```rust
use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Config {
    name: String,
    values: HashMap<String, i64>,
}

impl Config {
    fn new(name: &str) -> Self {
        Config {
            name: name.to_string(),
            values: HashMap::new(),
        }
    }

    fn set(&mut self, key: &str, value: i64) {
        self.values.insert(key.to_string(), value);
    }
}

fn main() {
    let mut config = Config::new("example");
    config.set("timeout", 30);
    config.set("retries", 3);
    println!("{:?}", config);
}
```

## Python

```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class Task:
    title: str
    done: bool = False
    priority: Optional[int] = None

def filter_pending(tasks: list[Task]) -> list[Task]:
    """Return only tasks that are not yet done."""
    return [t for t in tasks if not t.done]

if __name__ == "__main__":
    tasks = [
        Task("Write docs", priority=1),
        Task("Fix bug #42", done=True),
        Task("Add tests", priority=2),
    ]
    for task in filter_pending(tasks):
        print(f"TODO: {task.title}")
```

## TypeScript

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  role: "admin" | "user" | "guest";
}

async function fetchUsers(endpoint: string): Promise<User[]> {
  const response = await fetch(endpoint);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

const formatUser = (user: User): string =>
  `${user.name} <${user.email}> [${user.role}]`;

const main = async () => {
  const users = await fetchUsers("/api/users");
  users
    .filter((u) => u.role !== "guest")
    .map(formatUser)
    .forEach(console.log);
};
```

## Go

```go
package main

import (
	"fmt"
	"strings"
	"sync"
)

type Result struct {
	Word  string
	Count int
}

func countWords(text string) map[string]int {
	counts := make(map[string]int)
	for _, word := range strings.Fields(text) {
		counts[strings.ToLower(word)]++
	}
	return counts
}

func main() {
	texts := []string{
		"hello world hello",
		"world of code",
	}

	var wg sync.WaitGroup
	results := make(chan Result)

	for _, text := range texts {
		wg.Add(1)
		go func(t string) {
			defer wg.Done()
			for word, count := range countWords(t) {
				results <- Result{Word: word, Count: count}
			}
		}(text)
	}

	go func() {
		wg.Wait()
		close(results)
	}()

	for r := range results {
		fmt.Printf("%s: %d\n", r.Word, r.Count)
	}
}
```

## HTML

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Example Page</title>
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <header>
    <nav>
      <a href="/">Home</a>
      <a href="/about">About</a>
    </nav>
  </header>
  <main>
    <h1>Welcome</h1>
    <p>This is an <strong>example</strong> page.</p>
  </main>
</body>
</html>
```

## SQL

```sql
SELECT
    u.name,
    u.email,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id, u.name, u.email
HAVING COUNT(o.id) > 0
ORDER BY total_spent DESC
LIMIT 10;
```

## YAML

```yaml
name: deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: gleam build
      - name: Test
        run: gleam test
```

## Bash

```bash
#!/bin/bash
set -euo pipefail

readonly LOG_FILE="/var/log/deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

deploy() {
    local version="$1"
    log "Deploying version ${version}..."

    if [ -d "./dist" ]; then
        rm -rf ./dist
    fi

    gleam build && gleam run
    log "Deploy complete."
}

deploy "${1:-latest}"
```
