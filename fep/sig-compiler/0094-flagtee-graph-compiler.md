# FEP-0094: a Graph Compiler Framework for 3D-IC

**Status:** `Provisional`

**Created:** 2026-07-31

**Owner:** @github-tsingmicro-public-e

**SIG:** sig-compiler

**Target Version:** FlagOS 2.X

***

## Summary

A Graph Compiler Technology and Implementation for AI Chips with 3DRAM Architecture.

## Motivation

Currently, Flagtree/Triton only supports compiling individual Triton operators and running in PyTorch eager mode; it does not yet support PyTorch graph mode execution. Compared with eager mode, graph mode can achieve better performance.

### Goals

The goal is to improve the performance of AI chips with 3D DRAM architecture in both training and inference scenarios, within the framework of the Flagtree/Triton compiler.

### Non-Goals

NA

## Proposal

We hope to enable graph compilation in a way that is compatible with  vLLM/SGLang + PyTorch (for inference) and Megatron-LM + PyTorch (for training). For example, we can leverage the torch.compile framework to compile both full computational graph and subgraph of the model. The compiled graphs can then be dispatched and executed by PyTorch or vLLM. Alternative technical solutions that are more suitable may also be considered.

## Design Details

Based on further detailed discussion

## Packaging


## Test Plan

## Related PRs

## Implementation History

