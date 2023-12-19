# zava
Mini Java VM in Zig

## What it is

Zava is a Java<sup>*</sup> VM implementation in Zig. This is a sister project of [Gava](https://github.com/chaoyangnz/gava) which is using Go.
The goal of Zava is to implement a couple of features which are not capable of doing by Go, such as GC and fine control of memory allocation.

The reference of the implement is [JVM Spec 8 edition](https://docs.oracle.com/javase/specs/jvms/se8/html/) and it is supposed to be compatible with Java 8 bytecode.

--- 
> \* JAVA is a trademark of Oracle America, Inc.

## Roadmap

Feature:
- [x] type system definition
- [x] class file parser
- [x] instructions interpretion 
- [x] native methods bridge to support HelloWorld
- [x] class loading
  - [x] bootstrap class loader
  - [x] user defined class loader
- [x] string pool
- [x] basic reflection support (Class, Field, Method, Consutructor)
- [ ] multi-thread and concurrency
- [ ] garbage collector
- [ ] profiling and Debugger integration

Non-functional:
- [ ] sufficent unit test coverage
- [ ] code readability and clear documentation of high-level design
- [ ] mini ebook to describe how to evolve a mini VM from scratch
- [ ] VSCode debugging extension


## Get started

- HelloWorld
```
zig build

./zava HelloWorld
```

![demo](demo.gif)

## Debugging

A VS code launch.json is configured for your debugging.

And after running the program, a `zava.log` is produced to trace the execution.

- info level: only method calls are logged
- debug level: per instruction executions are also logged with the context




