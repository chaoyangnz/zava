# zava
Mini Java VM in Zig

## What it is

Zava is a Java VM implementation in Zig. This is a sister project of [Gava](https://github.com/chaoyangnz/gava) which is using Go.
The goal of Zava is to implement a couple of features which are not capable of doing by Go, such as GC and fine control of memory allocation.

The reference of the implement is [JVM Spec 8 edition](https://docs.oracle.com/javase/specs/jvms/se8/html/) and it is supposed to be compatible with Java 8 bytecode.

## Roadmap

- [x] type system definition
- [x] class file parser
- [x] instructions interpretion 
- [x] native methods bridge to support HelloWorld
- [ ] class loading
  - [x] bootstrap class loader
  - [ ] user defined class loader
- [x] string pool
- [x] basic reflection support (Class, Field, Method, Consutructor)
- [ ] garbage collector


## Get started

- HelloWorld
```
zig run src/main.zig
```
