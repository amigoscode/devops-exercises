# Submission - Smart Lead Capstone

> Copy this file into the root of your solution repository and fill it in. Keep it
> honest and concise - the reviewer reads this first.

## Your details

- **Name / Academy handle:**
- **Solution repository:** (link to your fork / repo)
- **Date:**

## How to run it

The reviewer will run exactly what you put here, on a machine with only Docker.

```bash
# clone
git clone <your-repo-url>
cd <your-repo>

# bring the whole system up
<your command here, e.g. docker compose up --build -d>
```

- **URL / port the API is on:**
- **Anything that must be set first (e.g. copy `.env.example` to `.env`):**

## Prove it works

Paste the commands you use to demonstrate the end-to-end flow, and what you expect to
see:

```bash
# submit a message
curl -X POST localhost:8080/api/v1/messages \
  -H 'Content-Type: application/json' \
  -d '{"content":"How much does the pro plan cost?"}'

# then a lead should appear
curl localhost:8080/api/v1/leads
```

## Design decisions (the important part)

Explain the choices you made and why. A few sentences each.

1. **Building the app image** - what base image(s), single or multi-stage, and why:

2. **Pointing the app at the containers** - which `application.properties` values you
   overrode, and how you passed them in:

3. **Startup ordering** - how you made the app wait for the database and queue to be
   *ready* (not just started):

4. **The queue** - how it gets created and how the app finds it:

5. **The AI call** - how you ran without a real HuggingFace key, and how a real key
   would be supplied:

6. **Persistence** - where the database data lives and how you confirmed it survives a
   restart:

## Reflection

Answer the questions from the capstone README:

1. Which `application.properties` values did you override, and why those exactly?
2. How did you guarantee the app does not start before the database and queue are ready,
   and how is that different from a plain `depends_on`?
3. Where does the database data live, and how did you prove it survives a restart?
4. How would you switch from the AI stub to a real HuggingFace key without changing the
   image or committing a secret?
5. What did you do to keep the final image small and safe, and what would you improve
   with more time?

## Known limitations / what I would do next

-
