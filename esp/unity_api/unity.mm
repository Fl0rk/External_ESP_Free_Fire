#import "unity.h"

Vector3 get_position_by_transform(mach_vm_address_t mach_transform_ptr, task_t task)
{
    mach_vm_address_t transObj = Read<mach_vm_address_t>(mach_transform_ptr + 0x10, task);
    if (!transObj) return Vector3{0,0,0};

    mach_vm_address_t matrix = Read<mach_vm_address_t>(transObj + 0x38, task); // dump memory and change addr
    if (!matrix) return Vector3{0,0,0};

    int index = Read<int>(transObj + 0x40, task); // dump memory and change addr

    mach_vm_address_t matrix_list = Read<mach_vm_address_t>(matrix + 0x18, task);
    mach_vm_address_t matrix_indices = Read<mach_vm_address_t>(matrix + 0x20, task);
    if (!matrix_list || !matrix_indices) return Vector3{0,0,0};

    Vector3 result = Read<Vector3>(matrix_list + (size_t)sizeof(TMatrix) * (size_t)index, task);
    int transformIndex = Read<int>(matrix_indices + (size_t)sizeof(int) * (size_t)index, task);

    if (transformIndex < 0) return result;

    while (transformIndex >= 0)
    {
        TMatrix tMatrix = Read<TMatrix>(matrix_list + (size_t)sizeof(TMatrix) * (size_t)transformIndex, task);

        float rotX = tMatrix.rotation.x;
        float rotY = tMatrix.rotation.y;
        float rotZ = tMatrix.rotation.z;
        float rotW = tMatrix.rotation.w;

        float scaleX = result.x * tMatrix.scale.x;
        float scaleY = result.y * tMatrix.scale.y;
        float scaleZ = result.z * tMatrix.scale.z;

        result.x = tMatrix.position.x + scaleX +
            (scaleX * ((rotY * rotY * -2.0f) - (rotZ * rotZ * 2.0f))) +
            (scaleY * ((rotW * rotZ * -2.0f) - (rotY * rotX * -2.0f))) +
            (scaleZ * ((rotZ * rotX * 2.0f) - (rotW * rotY * -2.0f)));
        result.y = tMatrix.position.y + scaleY +
            (scaleX * ((rotX * rotY * 2.0f) - (rotW * rotZ * -2.0f))) +
            (scaleY * ((rotZ * rotZ * -2.0f) - (rotX * rotX * 2.0f))) +
            (scaleZ * ((rotW * rotX * -2.0f) - (rotZ * rotY * -2.0f)));
        result.z = tMatrix.position.z + scaleZ +
            (scaleX * ((rotW * rotY * -2.0f) - (rotX * rotZ * -2.0f))) +
            (scaleY * ((rotY * rotZ * 2.0f) - (rotW * rotX * -2.0f))) +
            (scaleZ * ((rotX * rotX * -2.0f) - (rotY * rotY * 2.0f)));

        transformIndex = Read<int>(matrix_indices + (size_t)sizeof(int) * (size_t)transformIndex, task);
    }

    return result;
}


inline float Dot(const Vector3 &Vec1, const Vector3 &Vec2)
{
    return Vec1.x * Vec2.x + Vec1.y * Vec2.y + Vec1.z * Vec2.z;
}

Vector3 WorldToScreen(Vector3 object, mach_vm_address_t camera_ptr, CGFloat ScreenWidth, CGFloat ScreenHeight, task_t task)
{
    mach_vm_address_t internal = Read<mach_vm_address_t>(camera_ptr + 0x10, task);
    c_matrix mtx = Read<c_matrix>(internal + 0xc4, task); // dump memory and change addr

    Vector3 transVec = Vector3(mtx[0][3], mtx[1][3], mtx[2][3]);
    Vector3 rightVec = Vector3(mtx[0][0], mtx[1][0], mtx[2][0]);
    Vector3 upVec = Vector3(mtx[0][1], mtx[1][1], mtx[2][1]);

    float w = Dot(transVec, object) + mtx[3][3];
    if (w < 0.9f)
    {
        Vector3 v;
        v.x = v.y = v.z = 0;
        return v;
    }
        //return {0,0,0};

    float y = Dot(upVec, object) + mtx[3][1];
    float x = Dot(rightVec, object) + mtx[3][0];

    return Vector3((ScreenWidth / 2) * (1.f + x / w), (ScreenHeight / 2) * (1.f - y / w), w);
}

