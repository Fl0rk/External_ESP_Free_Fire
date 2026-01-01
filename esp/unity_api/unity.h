#import "../helpers/pid.h"
#import "../helpers/Vector3.h"

#import <cstddef>
#import <cstring>
#import <cstdlib>
#import <dlfcn.h>
#import <spawn.h>
#import <unistd.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

#pragma once

#include <vector>
#include <functional>
#include <utility>

struct Vector4
{
    float x, y, z, w;
};

struct TMatrix
{
    Vector4 position;
    Vector4 rotation;
    Vector4 scale;
};

struct c_matrix
{
    float m[4][4];
    float *operator[](int index) { return m[index]; }
};


#pragma mark - cheat helpers

template<typename T>
struct Array {
    void *klass;
    void *monitor;
    void *bounds;
    uintptr_t capacity;
    T m_Items[65535];
    
    int32_t getCapacity() { return capacity; }
    T *getPointer() { return m_Items; }
    
    std::vector<T> toCPPlist() {
        std::vector<T> ret;
        for(int i = 0; i < capacity; i++) ret.push_back(m_Items[i]);
        
        return std::move(ret);
    }

    std::vector<T> toCPPlist(std::function<bool(T)> predicate) {
        std::vector<T> ret;
        for(int i = 0; i < capacity; i++) {
            if(predicate(m_Items[i])) {
                ret.push_back(m_Items[i]);
            }
        }
        return ret;
    }
    
    bool copyFrom(const std::vector<T> &vec) {
        return copyFrom((T *)vec.data(), (int)vec.size());
    }
    
    bool copyFrom(T *arr, int size) {
        if(size < capacity) return false;
        memcpy(m_Items, arr, size * sizeof(T));
        
        return true;
    }
    
    void copyTo(T *arr) {
        if(!CheckObj(m_Items)) return;
        memcpy(arr, m_Items, sizeof(T) * capacity);
    }
    
    T &operator[](int index) {
        if(getCapacity() < index) {
            T a = T();
            return a;
        }
        return m_Items[index];
    }
    
    const T at(int index) {
        if(getCapacity() <= index || empty()) {
            T a = T();
            return a;
        }
        return m_Items[index];
    }
    
    bool empty() {
        return getCapacity() <= 0;
    }
    
    static Array<T> *Create(int capacity) {
        Array<T> *monoArr = (Array<T> *)malloc(sizeof(Array) + sizeof(T) * capacity);
        monoArr->capacity = capacity;
        return monoArr;
    }
    
    static Array<T> *Create(const std::vector<T> &vec) {
        return Create(vec.data(), vec.size());
    }
    
    static Array<T> *Create(T *arr, int size) {
        Array<T> *monoArr = Create(size);
        monoArr->copyFrom(arr, size);
        return monoArr;
    }
};

inline bool isNull(uintptr_t what) {
    return what;
}

template<typename T>
struct List {
    void *klass;
    void *monitor;
    Array<T> *items; // 0x0
    int size; // 0x0
    int version; // 0x0
    void *syncRoot; // 0x0
    Array<T> *s_emptyArray; // 0x0
    
    std::vector<T> toCPPlist() { return items->toCPPlist(); }
    std::vector<T> toCPPlist(std::function<bool(T)> predicate) { return items->toCPPlist(predicate); }
    int getSize() { return size; }
    int getVersion() { return version; }
};


Vector3 get_position_by_transform(mach_vm_address_t mach_transform_ptr, task_t task);
inline float Dot(const Vector3 &Vec1, const Vector3 &Vec2);
Vector3 WorldToScreen(Vector3 object, mach_vm_address_t camera_ptr, CGFloat ScreenWidth, CGFloat ScreenHeight, task_t task);
