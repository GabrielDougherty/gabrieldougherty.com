---
title: "Things That Surprised Me About CMake"
date: 2023-07-23T14:53:32-04:00
draft: false
---

# Intro

In my current job for the past year I have been using CMake for all my C++ development, working on financial software in a large CMake project with hundreds of executable targets and around 3 million LoC. In the course of getting up to speed on CMake, I ran into some things that surprised me.

![Warped CMake Screenshot](/warped-cmake-screenshot.png#l)

# Implicit includes

This is a simple one - when you specify a dependency with `target_link_libraries`, if the CMake rule that builds that target has specified its Public include directories via `target_include_directories`, then those include files are propogated.

So if you work in a project that follows the convention:

- Specify public include files for all targets with `target_include_directories( ... PUBLIC)`

Then any dependency set up with `target_link_libraries` will set up the include directories properly as well.

So in short "link" implies that the include files are available, too, for all targets built in a CMake project that follow this convention. I find this a bit surprising since I mentally have thought of linking being different from include directories. But now that I've worked in this system for a while, I don't mind it.

# CMake project reloading

Any time a CMakeLists.txt file in a CMake project is modified, the entire CMake project needs to be reloaded for the change to take effect. CMake doesn't support incrementally loading just one part of a project, so even if you just add one file to a target's sources, the entire project must be reloaded including any computationally expensive rules. Of course, during project reload we can't compile or use CLion go-to-definition or refactoring tools. This gets painful for larger projects that have long load times.

# Globally scoped targets

All target names in a CMake project inhabit the same global scope, and there isn't any built in namespacing functionality based (for example) on the directory hierarchy, although there is a [recommended convention](https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html) to use double-colon separated names for imported targets. In a larger project with gratuitous use of `add_subdirectory`, this ultimately leads to longer target names like `ACMEmoduleNameComponent` where

- ACME = company target prefix for ACME Company to distinguish between targets of company source code and third party dependencies
- moduleName = the module name the target inhabits - for example product group like Accounting
- Component = the actual piece of software being built by this target, for example a Stock Record Service

This gets annoying especially for command line development since these three components of the target name duplicate information that is already in the filesystem:

```
# in project root
cd cmake/
cmake ..
cd ModuleName/Component/src
make ACMEmoduleNameComponent
```

`ModuleName/Component/src` already specifies the 3 components:

- it identifies the module as first party (built by us) since 3rd party are in system directories or vendored in `third_party/`
- It identifies the module name via `ModuleName/`
- It identifies the component name via `Component/`


Therefore, I would prefer to only need to type `make ./Component` here.

# Named return values

CMake functions return values by setting a variable in the PARENT scope.

The function below is the skeleton of a pretend rule to generate C++ files and associated targets from XML specifications and return them in a variable `${src_name}_GENERATED_TARGETS`.

```
function(acme_generate_targets src_name srcs)
    message("generating C++ targets from sources: ${srcs}")
    ... # generation done here
    src_name =  ...
    targets = ....
    set(${src_name}_GENERATED_TARGETS ${targets} PARENT_SCOPE)
endfunction()
```

after calling the function, the variable `${src_name}_GENERATED_TARGETS` can be used in the parent scope:

```
set(SRCS "user_model.xml organization_model.xml")
acme_generate_targets("core_models" ${SRCS})
message("Successfully generated targets: ${core_models_GENERATED_TARGETS}")
target_link_libraries(MyCoreService PRIVATE ${core_models_GENERATED_TARGETS})
```

This is a bit of an odd programming language feature, since the function decides the name of the return variable used in the parent scope when normally (in C++ or Python or most languages) the author of the parent scope would decide the name of the variable.

# find_package() must be called after project()

I recently had a CMake project I was developing at home where I had just made the project and installed SDL2 with vcpkg on Windows and I did something like this:

```
cmake_minimum_required (VERSION 3.8)

find_package(SDL2 REQUIRED)

project("my-proj")

# Include sub-projects.
add_subdirectory("src")
```

And I kept getting errors from find_package that SDL2 wasn't found. I tried reinstalling multiple ways with vcpkg until finally realizing that I simply needed to put `project` before `find_package`:


```
cmake_minimum_required (VERSION 3.8)
project("my-proj")

find_package(SDL2 REQUIRED)

# Include sub-projects.
add_subdirectory("src")
```

I didn't notice anything in the documentation for find_package() or project() about this behavior, but maybe I just missed something. In any case, I found it surprising :-)

# Variable names

If you write a variable like $VARNAME instead of ${VARNAME} it will work with CMake + Make, but will break when you switch to the Ninja generator.

# Missing libraries

CMake won't complain about a missing or misspelled library in target_link_libraries

```
target_link_libraries(
        MyLib
    PRIVATE
        hellowhatsup # invalid lib name
)

```

will build fine.

> Update July 24: LoC was off by two orders of magnitude. Fixed grammar, added note about variable names and missing libraries.