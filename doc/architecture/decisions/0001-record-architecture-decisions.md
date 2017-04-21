# 1. Record architecture decisions

Date: 16/04/2017

## Status

Accepted

## Context

We need to record the architectural decisions made on this project.

## Decision

We will use Architecture Decision Records, as [described by Michael Nygard in his article](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions).
In order to make this easier to handle, [adr-tools](https://github.com/npryce/adr-tools) should be used to create new entries, as well as to supersede existing ones.

In a nutshell:

* ADRs are basically lightweight RFCs.
* We will keep a collection of records for "architecturally significant" decisions: those that affect the structure, non-functional characteristics, dependencies, interfaces, or construction techniques.
* The files are similar to this one (plaintext, same structure).
* ADRs are numbered sequentially. Numbers will not be reused.
* A decision will be considered *immutable* (except for the status). Amendments go to a new ADR that supersedes the old one.
* If a decision is reversed or changed, the original file is kept around, but marked as superseded. Use `adr` for doing that -- e.g., `adr new -s 12 Use PostgreSQL Database` (see `adr help new`) -- in order to do this with a consistent style (the ADR's status is changed and links are inserted).


## Consequences

See Michael Nygard's article, linked above.
