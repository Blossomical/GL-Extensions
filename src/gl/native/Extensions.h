#if defined(_WIN32)
#include <Windows.h>
#include <GL/gl.h>
#elif defined(__APPLE__)
#include <OpenGL/gl3.h>
#include <OpenGL/gl3ext.h>
#else
#include <GL/gl.h>
#include <GL/glx.h> // For glXGetProcAddress
#endif

#include <cstdio>
#include <cstdint>
#include <cstddef>
#include <functional>
#include <hxcpp.h>
#include <hl.h>

#pragma comment(lib, "opengl32.lib")

#ifndef GLsizeiptr
typedef ptrdiff_t GLsizeiptr;
#endif

#ifndef GLintptr
typedef ptrdiff_t GLintptr;
#endif

#ifndef APIENTRY
#if defined(_WIN32)
#define APIENTRY __stdcall
#else
#define APIENTRY
#endif
#endif

#ifndef GLenum
typedef unsigned int GLenum;
#endif

#ifndef GLboolean
typedef unsigned char GLboolean;
#endif

#ifndef GLbitfield
typedef unsigned int GLbitfield;
#endif

#ifndef GLvoid
typedef void GLvoid;
#endif

#ifndef GLbyte
typedef signed char GLbyte;
#endif

#ifndef GLubyte
typedef uint8_t GLubyte;
#endif

#ifndef GLshort
typedef int16_t GLshort;
#endif

#ifndef GLushort
typedef uint16_t GLushort;
#endif

#ifndef GLint
typedef int GLint;
#endif

#ifndef GLuint
typedef unsigned int GLuint;
#endif

#ifndef GLhandleARB
typedef unsigned int GLhandleARB;
#endif

#ifndef GLclampx
typedef int32_t GLclampx;
#endif

#ifndef GLsizei
typedef int GLsizei;
#endif

#ifndef GLfloat
typedef float GLfloat;
#endif

#ifndef GLclampf
typedef float GLclampf;
#endif

#ifndef GLdouble
typedef double GLdouble;
#endif

#ifndef GLclampd
typedef double GLclampd;
#endif

#ifndef GLeqlClientBufferEXT
typedef void *GLeglClientBufferEXT;
#endif

#ifndef GLeqlImageOES
typedef void *GLeglImageOES;
#endif

#ifndef GLchar
typedef char GLchar;
#endif

#ifndef GLcharARB
typedef char GLcharARB;
#endif

#ifndef GLhalf
typedef uint16_t GLhalf;
#endif

#ifndef GLhalfARB
typedef uint16_t GLhalfARB;
#endif

#ifndef GLfixed
typedef int32_t GLfixed;
#endif

#ifndef GLintptr
typedef intptr_t GLintptr;
#endif

#ifndef GLintptrARB
typedef intptr_t GLintptrARB;
#endif

#ifndef GLsizeiptr
typedef ptrdiff_t GLsizeiptr;
#endif

#ifndef GLsizeiptrARB
typedef size_t GLsizeiptrARB;
#endif

#ifndef GLint64
typedef int64_t GLint64;
#endif

#ifndef GLint64EXT
typedef int64_t GLint64EXT;
#endif

#ifndef GLuint64
typedef uint64_t GLuint64;
#endif

#ifndef GLuint64EXT
typedef uint64_t GLuint64EXT;
#endif

#ifndef GLsync
typedef struct __GLsync *GLsync;
#endif

struct _cl_context;
struct _cl_event;
typedef unsigned short GLhalfNV;
typedef GLintptr GLvdpauSurfaceNV;

using GLDEBUGPROC = std::function<void(GLenum, GLenum, GLuint, GLenum, GLsizei, const GLchar *, const void *)>;
using GLDEBUGPROCARB = std::function<void(GLenum, GLenum, GLuint, GLenum, GLsizei, const GLchar *, const void *)>;
using GLDEBUGPROCKHR = std::function<void(GLenum, GLenum, GLuint, GLenum, GLsizei, const GLchar *, const void *)>;
using GLDEBUGPROCAMD = std::function<void(GLuint, GLenum, GLenum, GLsizei, const GLchar *, void *)>;
using GLVULKANPROCNV = std::function<void()>;

static void *getProc(const char *name)
{
#if defined(_WIN32)
    void *p = (void *)wglGetProcAddress(name);
    if (!p)
    {
        HMODULE lib = GetModuleHandleA("opengl32.dll");
        if (lib)
            p = (void *)GetProcAddress(lib, name);
    }
    return p;

#elif defined(__APPLE__)
    // No dynamic loading needed: all symbols already linked
    return (void *)dlsym(RTLD_DEFAULT, name);

#else
    return (void *)glXGetProcAddress((const GLubyte *)name);
#endif
}

#undef HL_NAME
#define STRFY(x) #x
#define HL_NAME(n) glExtensions_##n
#if defined(__APPLE__)

#define DEFGL(type, name, glArgs, funcArgs, callArgs) \
    type glExtensions__##name funcArgs                \
    {                                                 \
        return (type)gl##name callArgs;               \
    }

#define DEFGL_HL(type, name, glArgs, funcArgs, callArgs) \
    HL_PRIM type HL_NAME(name) funcArgs                  \
    {                                                    \
        return (type)gl##name callArgs;                  \
    }
#else

#define DEFGL(type, name, glArgs, funcArgs, callArgs)                         \
    typedef type(APIENTRY *name##__TYPEDEF) glArgs;                           \
    type glExtensions__##name funcArgs                                        \
    {                                                                         \
        name##__TYPEDEF gl##name = (name##__TYPEDEF)getProc(STRFY(gl##name)); \
        return (type)gl##name callArgs;                                       \
    }

#define DEFGL_HL(type, name, glArgs, funcArgs, callArgs)                      \
    typedef type(APIENTRY *name##__TYPEDEF) glArgs;                           \
    HL_PRIM type HL_NAME(name) funcArgs                                       \
    {                                                                         \
        name##__TYPEDEF gl##name = (name##__TYPEDEF)getProc(STRFY(gl##name)); \
        return (type)gl##name callArgs;                                       \
    }
#endif

typedef void(__stdcall *ClearBufferiv__TYPEDEF)(GLenum, GLint, const GLint *);
void glExtensions_ClearBufferiv(int buffer, int drawbuffer, double value)
{
    ClearBufferiv__TYPEDEF glClearBufferiv = (ClearBufferiv__TYPEDEF)getProc("glClearBufferiv");
    return (void)glClearBufferiv(buffer, drawbuffer, (GLint *)(uintptr_t)value);
}