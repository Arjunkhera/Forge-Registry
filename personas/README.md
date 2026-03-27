# Personas Registry

This directory contains persona artifacts for the Forge registry.

## What is a Persona?

A persona is a first-class artifact type that defines a named role identity for use in
workspaces and sessions. Personas capture the mindset, goals, concerns, and communication
style of a role — giving agents and skill scripts a consistent behavioral frame to operate
within.

Personas are referenced from workspace configs via the `personas:` array field in
`metadata.yaml`. Forge resolves and installs them alongside skills, agents, and plugins
during workspace creation.

## Directory Layout

Each persona lives in its own subdirectory named by its artifact id:

```
personas/
  README.md              # this file
  _template/             # reference template for new personas
    PERSONA.md           # identity document template
    metadata.yaml        # schema example
  <persona-id>/
    PERSONA.md           # identity document
    metadata.yaml        # artifact metadata
```

## Creating a New Persona

1. Copy `_template/` to a new directory named after your persona id.
2. Fill in `metadata.yaml` with id, name, version, description, tags, and any dependencies.
3. Fill in `PERSONA.md` with the four required sections: Identity, Goals, Concerns,
   Communication Style.
4. Reference the persona id in the relevant workspace config `metadata.yaml` under
   `personas:`.
