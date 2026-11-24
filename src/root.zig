const std = @import("std");

const assert = std.debug.assert;
const expect = std.testing.expect;

pub fn Vec(comptime T: type, comptime len: u8) type {
    return struct {
        const Self = @This();

        pub const Vector = @Vector(len, T);

        elements: Vector,

        pub inline fn from(elements: Vector) Self {
            return .{ .elements = elements };
        }

        pub inline fn splat(element: T) Self {
            return from(@splat(element));
        }

        pub inline fn get(vec: Self, comptime index: u32) T {
            return vec.elements[index];
        }

        pub inline fn set(vec: *Self, comptime index: u32, value: T) void {
            vec.elements[index] = value;
        }

        pub inline fn compare(a: Self, comptime op: std.math.CompareOperator, b: Self) Vec(bool, len) {
            return .from(switch (op) {
                .eq => a.elements == b.elements,
                .neq => a.elements != b.elements,

                .gt => a.elements > b.elements,
                .gte => a.elements >= b.elements,

                .lt => a.elements < b.elements,
                .lte => a.elements <= b.elements,
            });
        }

        pub fn near(a: Self, b: Self, @"error": Self) Vec(bool, len) {
            return a.sub(b).abs().compare(.lte, @"error".abs());
        }

        pub inline fn nan(vec: Self) Vec(bool, len) {
            return vec.compare(.eq, vec);
        }

        pub inline fn abs(vec: Self) Self {
            return from(@abs(vec.elements));
        }

        pub inline fn add(a: Self, b: Self) Self {
            return from(a.elements + b.elements);
        }

        pub inline fn sub(a: Self, b: Self) Self {
            return from(a.elements - b.elements);
        }

        pub inline fn multiply(a: Self, b: Self) Self {
            return from(a.elements * b.elements);
        }

        pub inline fn scale(vec: Self, scalar: T) Self {
            return vec.multiply(splat(scalar));
        }

        pub fn divide(a: Self, b: Self) Self {
            assert(b.compare(.neq, splat(0)).reduce(.Or));

            return from(a.elements / b.elements);
        }

        pub inline fn select(a: Self, pred: Vec(bool, len), b: Self) Self {
            return from(@select(T, pred.elements, a.elements, b.elements));
        }

        pub inline fn shuffle(a: Self, comptime mask: Vec(i32, len), b: Self) Self {
            return from(@shuffle(T, a.elements, b.elements, mask.elements));
        }

        pub inline fn reduce(vec: Self, comptime op: std.lang.ReduceOp) T {
            return @reduce(op, vec.elements);
        }

        pub fn dot(a: Self, b: Self) T {
            return a.multiply(b).reduce(.Add);
        }

        pub fn length(vec: Self) T {
            return @sqrt(vec.dot(vec));
        }

        pub fn normalize(vec: Self) Self {
            const mag = vec.length();
            return vec.divide(splat(1).select(.splat(mag == 0), splat(mag)));
        }
    };
}

pub fn Vec2(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec(T, 2);
        pub const Component = enum(u32) {
            x = 0,
            y = 1,

            pub inline fn int(component: @This()) u32 {
                return @backingInt(component);
            }
        };

        raw: Vector,

        pub inline fn from(vec: Vector) Self {
            return .{ .raw = vec };
        }

        pub inline fn splat(element: T) Self {
            return as(@splat(element));
        }

        pub inline fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub inline fn init(x: T, y: T) Self {
            return as(.{ x, y });
        }

        pub inline fn get(vec: Self, comptime component: Component) T {
            return vec.raw.get(component.int());
        }

        pub inline fn set(vec: *Self, comptime component: Component, value: T) void {
            vec.raw.set(component.int(), value);
        }

        pub inline fn compare(a: Self, comptime op: std.math.CompareOperator, b: Self) Vec2(bool) {
            return .from(a.raw.compare(op, b.raw));
        }

        pub inline fn near(a: Self, b: Self, @"error": Self) Vec2(bool) {
            return .from(a.raw.near(b.raw, @"error".raw));
        }

        pub inline fn nan(vec: Self) Vec2(bool) {
            return vec.compare(.eq, vec);
        }

        pub inline fn abs(vec: Self) Self {
            return from(vec.raw.abs());
        }

        pub inline fn add(a: Self, b: Self) Self {
            return from(a.raw.add(b.raw));
        }

        pub inline fn sub(a: Self, b: Self) Self {
            return from(a.raw.sub(b.raw));
        }

        pub inline fn multiply(a: Self, b: Self) Self {
            return from(a.raw.multiply(b.raw));
        }

        pub inline fn scale(vec: Self, scalar: T) Self {
            return vec.multiply(splat(scalar));
        }

        pub inline fn divide(a: Self, b: Self) Self {
            return from(a.raw.divide(b.raw));
        }

        pub inline fn select(a: Self, pred: Vec2(bool), b: Self) Self {
            return from(a.raw.select(pred.raw, b.raw));
        }

        pub inline fn shuffle(vec: Self, comptime x: Component, comptime y: Component) Self {
            return from(vec.raw.shuffle(.from(.{ x.int(), y.int() }), .splat(0)));
        }

        pub inline fn reduce(vec: Self, comptime op: std.lang.ReduceOp) T {
            return vec.raw.reduce(op);
        }

        pub inline fn dot(a: Self, b: Self) T {
            return a.raw.dot(b.raw);
        }

        pub inline fn length(vec: Self) T {
            return vec.raw.length();
        }

        pub inline fn normalize(vec: Self) Self {
            return from(vec.raw.normalize());
        }
    };
}

pub fn Vec3(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec(T, 4);
        pub const Component = enum(u32) {
            x = 0,
            y = 1,
            z = 2,

            pub inline fn int(component: @This()) u32 {
                return @backingInt(component);
            }
        };

        raw: Vector,

        pub inline fn init(x: T, y: T, z: T) Self {
            return .{ .raw = .{ x, y, z, 0 } };
        }

        pub inline fn as(elements: Vector.Vector) Self {
            return init(elements[0], elements[1], elements[2]);
        }

        pub inline fn from(vec: Vector) Self {
            return .{ .raw = vec.shuffle(.from(.{ 0, 1, 2, -1 }), .splat(0)) };
        }

        pub inline fn splat(element: T) Self {
            return init(element, element, element);
        }

        pub inline fn get(vec: Self, comptime component: Component) T {
            return vec.raw.get(component.int());
        }

        pub inline fn set(vec: *Self, comptime component: Component, value: T) void {
            vec.raw.set(component.int(), value);
        }

        pub inline fn compare(a: Self, comptime op: std.math.CompareOperator, b: Self) Vec3(bool) {
            return .from(a.raw.compare(op, b.raw));
        }

        pub inline fn near(a: Self, b: Self, @"error": Self) Vec3(bool) {
            return .from(a.raw.near(b.raw, @"error".raw));
        }

        pub inline fn nan(vec: Self) Vec3(bool) {
            return vec.compare(.eq, vec);
        }

        pub inline fn abs(vec: Self) Self {
            return from(vec.raw.abs());
        }

        pub inline fn add(a: Self, b: Self) Self {
            return from(a.raw.add(b.raw));
        }

        pub inline fn sub(a: Self, b: Self) Self {
            return from(a.raw.sub(b.raw));
        }

        pub inline fn multiply(a: Self, b: Self) Self {
            return from(a.raw.multiply(b.raw));
        }

        pub inline fn scale(vec: Self, scalar: T) Self {
            return vec.multiply(splat(scalar));
        }

        pub inline fn divide(a: Self, b: Self) Self {
            return from(a.raw.divide(b.raw.shuffle(.from(.{ 0, 1, 2, -1 }), .splat(1))));
        }

        pub inline fn select(a: Self, pred: Vec3(bool), b: Self) Self {
            return from(a.raw.select(pred.raw, b.raw));
        }

        pub inline fn shuffle(vec: Self, comptime x: Component, comptime y: Component, comptime z: Component) Self {
            return .{ .raw = vec.raw.shuffle(.from(.{ x.int(), y.int(), z.int(), -1 }), .splat(0)) };
        }

        pub inline fn reduce(vec: Self, comptime op: std.lang.ReduceOp) T {
            return vec.raw.reduce(op);
        }

        pub inline fn dot(a: Self, b: Self) T {
            return a.raw.dot(b.raw);
        }

        pub inline fn length(vec: Self) T {
            return vec.raw.length();
        }

        pub inline fn normalize(vec: Self) Self {
            return from(vec.raw.normalize());
        }

        pub fn cross(a: Self, b: Self) Self {
            const ayzx_bzxy = a.shuffle(.y, .z, .x).multiply(b.shuffle(.z, .x, .y));
            const azxy_byzx = a.shuffle(.z, .x, .y).multiply(b.shuffle(.y, .z, .x));

            return ayzx_bzxy.sub(azxy_byzx);
        }

        pub fn getQuaternion(axis: Self, radians: T) Quaternion(T) {
            const mag = axis.length();
            const half_radians = radians * 0.5;
            const pred = Quaternion(bool).splat(mag == 0);

            const Quat = Quaternion(T);
            const numerator = Quat.identity.select(pred, .from(axis.scale(@sin(half_radians)).raw));
            const denominator = Quat.splat(1).select(pred, .splat(mag));

            return .from(numerator.raw.divide(denominator.raw).shuffle(.from(.{ -1, 0, 1, 2 }), .splat(@cos(half_radians))));
        }

        pub fn rotate(vec: Self, quat: Quaternion(T)) Self {
            return quat.multiply(.from(vec.raw.shuffle(.from(.{ -1, 0, 1, 2 }), .splat(0)))).multiply(quat.inverse()).getVector();
        }
    };
}

pub fn Vec4(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec(T, 4);
        pub const Component = enum(u32) {
            x = 0,
            y = 1,
            z = 2,
            w = 3,

            pub inline fn int(component: @This()) u32 {
                return @backingInt(component);
            }
        };

        raw: Vector,

        pub inline fn from(vec: Vector) Self {
            return .{ .raw = vec };
        }

        pub inline fn splat(element: T) Self {
            return as(@splat(element));
        }

        pub inline fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub inline fn init(x: T, y: T, z: T, w: T) Self {
            return as(.{ x, y, z, w });
        }

        pub inline fn get(vec: Self, comptime component: Component) T {
            return vec.raw.get(component.int());
        }

        pub inline fn set(vec: *Self, comptime component: Component, value: T) void {
            vec.raw.set(component.int(), value);
        }

        pub inline fn compare(a: Self, comptime op: std.math.CompareOperator, b: Self) Vec4(bool) {
            return .from(a.raw.compare(op, b.raw));
        }

        pub inline fn near(a: Self, b: Self, @"error": Self) Vec4(bool) {
            return .from(a.raw.near(b.raw, @"error".raw));
        }

        pub inline fn nan(vec: Self) Vec4(bool) {
            return vec.compare(.eq, vec);
        }

        pub inline fn abs(vec: Self) Self {
            return from(vec.raw.abs());
        }

        pub inline fn add(a: Self, b: Self) Self {
            return from(a.raw.add(b.raw));
        }

        pub inline fn sub(a: Self, b: Self) Self {
            return from(a.raw.sub(b.raw));
        }

        pub inline fn multiply(a: Self, b: Self) Self {
            return from(a.raw.multiply(b.raw));
        }

        pub inline fn scale(vec: Self, scalar: T) Self {
            return vec.multiply(splat(scalar));
        }

        pub inline fn divide(a: Self, b: Self) Self {
            return from(a.raw.divide(b.raw));
        }

        pub inline fn select(a: Self, pred: Vec4(bool), b: Self) Self {
            return from(a.raw.select(pred.raw, b.raw));
        }

        pub inline fn shuffle(vec: Self, comptime x: Component, comptime y: Component, comptime z: Component, comptime w: Component) Self {
            return from(vec.raw.shuffle(.from(.{ x.int(), y.int(), z.int(), w.int() }), .splat(0)));
        }

        pub inline fn reduce(vec: Self, comptime op: std.lang.ReduceOp) T {
            return vec.raw.reduce(op);
        }

        pub inline fn dot(a: Self, b: Self) T {
            return a.raw.dot(b.raw);
        }

        pub inline fn length(vec: Self) T {
            return vec.raw.length();
        }

        pub inline fn normalize(vec: Self) Self {
            return from(vec.raw.normalize());
        }

        pub fn lerp(vec: Self, target: Self, t: T) Self {
            return vec.scale(1 - t).add(target.scale(t));
        }
    };
}

pub fn Quaternion(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec(T, 4);
        pub const Component = enum(u32) {
            w = 0,
            x = 1,
            y = 2,
            z = 3,

            pub inline fn int(component: @This()) u32 {
                return @backingInt(component);
            }
        };

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.set(.w, 1);

            break :identity tmp;
        };

        raw: Vector,

        pub inline fn from(elements: Vector) Self {
            return .{ .raw = elements };
        }

        pub inline fn splat(element: T) Self {
            return as(@splat(element));
        }

        pub inline fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub inline fn init(w: T, x: T, y: T, z: T) Self {
            return as(.{ w, x, y, z });
        }

        pub inline fn getVector(quat: Self) Vec3(T) {
            return .from(quat.shuffle(.x, .y, .z, .w).raw);
        }

        pub inline fn get(quat: Self, comptime component: Component) T {
            return quat.raw.get(component.int());
        }

        pub inline fn set(quat: *Self, comptime component: Component, value: T) void {
            quat.raw.set(component.int(), value);
        }

        pub inline fn compare(a: Self, comptime op: std.math.CompareOperator, b: Self) Quaternion(bool) {
            return .from(a.raw.compare(op, b.raw));
        }

        pub inline fn near(a: Self, b: Self, @"error": Self) Quaternion(bool) {
            return .from(a.raw.near(b.raw, @"error".raw));
        }

        pub inline fn nan(quat: Self) Quaternion(bool) {
            return quat.compare(.eq, quat);
        }

        pub inline fn abs(quat: Self) Self {
            return from(quat.raw.abs());
        }

        pub inline fn add(a: Self, b: Self) Self {
            return from(a.raw.add(b.raw));
        }

        pub inline fn sub(a: Self, b: Self) Self {
            return from(a.raw.sub(b.raw));
        }

        pub inline fn scale(quat: Self, scalar: T) Self {
            return from(quat.raw.scale(scalar));
        }

        pub inline fn select(a: Self, pred: Quaternion(bool), b: Self) Self {
            return from(a.raw.select(pred.raw, b.raw));
        }

        pub inline fn shuffle(quat: Self, comptime w: Component, comptime x: Component, comptime y: Component, comptime z: Component) Self {
            return from(quat.raw.shuffle(.from(.{ w.int(), x.int(), y.int(), z.int() }), splat(0)));
        }

        pub inline fn reduce(quat: Self, comptime op: std.lang.ReduceOp) T {
            return quat.raw.reduce(op);
        }

        pub inline fn dot(a: Self, b: Self) T {
            return a.raw.dot(b.raw);
        }

        pub inline fn length(quat: Self) T {
            return quat.raw.length();
        }

        pub inline fn normalize(quat: Self) Self {
            return from(quat.raw.normalize());
        }

        pub fn multiply(a: Self, b: Self) Self {
            const w2 = b.get(.w);
            const w1 = a.get(.w);
            const v2 = b.getVector();
            const v1 = a.getVector();

            const vector = v2.scale(w1).add(v1.scale(w2));
            var result = from(vector.add(v1.cross(v2)));
            result.shuffle(.z, .w, .x, .y);
            result.set(.w, (w1 * w2) - v1.dot(v2));

            return result;
        }

        pub inline fn conjugate(quat: Self) Self {
            return from(quat.raw.multiply(.from(.{ 1, -1, -1, -1 })));
        }

        pub fn inverse(quat: Self) Self {
            const dot_product = quat.dot(quat);
            const pred = Quaternion(bool).splat(dot_product == 0);

            const numerator = identity.select(pred, quat.conjugate());
            const denominator = splat(1).select(pred, .splat(dot_product));

            return from(numerator.raw.divide(denominator.raw));
        }
    };
}

pub fn Mat2(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec2(T);

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.columns[0].set(.x, 1);
            tmp.columns[1].set(.y, 1);

            break :identity tmp;
        };

        columns: [2]Vector,

        pub inline fn from(c0: Vector, c1: Vector) Self {
            return .{ .columns = .{ c0, c1 } };
        }

        pub inline fn splat(element: T) Self {
            return .{ .columns = @splat(.splat(element)) };
        }

        pub fn add(a: Self, b: Self) Self {
            return from(a.columns[0].add(b.columns[0]), a.columns[1].add(b.columns[1]));
        }

        pub fn sub(a: Self, b: Self) Self {
            return from(a.columns[0].sub(b.columns[0]), a.columns[1].sub(b.columns[1]));
        }

        pub fn multiply(a: Self, b: Self) Self {
            const transposed = a.transpose();
            const ar0 = transposed.columns[0];
            const ar1 = transposed.columns[1];

            return from(.init(
                ar0.dot(b.columns[0]),
                ar1.dot(b.columns[0]),
            ), .init(
                ar0.dot(b.columns[1]),
                ar1.dot(b.columns[1]),
            ));
        }

        pub fn scale(mat: Self, scalar: T) Self {
            return from(mat.columns[0].scale(scalar), mat.columns[1].scale(scalar));
        }

        pub fn transpose(mat: Self) Self {
            var r = mat;
            r.columns[0].set(.y, r.columns[1].get(.x));
            r.columns[1].set(.x, r.columns[0].get(.y));

            return r;
        }
    };
}

pub fn Mat3(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec3(T);

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.columns[0].set(.x, 1);
            tmp.columns[1].set(.y, 1);
            tmp.columns[2].set(.z, 1);

            break :identity tmp;
        };

        columns: [3]Vector,

        pub inline fn from(c0: Vector, c1: Vector, c2: Vector) Self {
            return .{ .columns = .{ c0, c1, c2 } };
        }

        pub inline fn splat(element: T) Self {
            return .{ .columns = @splat(.splat(element)) };
        }

        pub fn add(a: Self, b: Self) Self {
            return from(a.columns[0].add(b.columns[0]), a.columns[1].add(b.columns[1]), a.columns[2].add(b.columns[2]));
        }

        pub fn sub(a: Self, b: Self) Self {
            return from(a.columns[0].sub(b.columns[0]), a.columns[1].sub(b.columns[1]), a.columns[2].sub(b.columns[2]));
        }

        pub fn multiply(a: Self, b: Self) Self {
            const transposed = a.transpose();
            const ar0 = transposed.columns[0];
            const ar1 = transposed.columns[1];
            const ar2 = transposed.columns[2];

            return from(.init(
                ar0.dot(b.columns[0]),
                ar1.dot(b.columns[0]),
                ar2.dot(b.columns[0]),
            ), .init(
                ar0.dot(b.columns[1]),
                ar1.dot(b.columns[1]),
                ar2.dot(b.columns[1]),
            ), .init(
                ar0.dot(b.columns[2]),
                ar1.dot(b.columns[2]),
                ar2.dot(b.columns[2]),
            ));
        }

        pub fn scale(mat: Self, scalar: T) Self {
            return from(mat.columns[0].scale(scalar), mat.columns[1].scale(scalar), mat.columns[2].scale(scalar));
        }

        pub fn transpose(mat: Self) Self {
            var r = mat;
            r.columns[0].set(.y, mat.columns[1].get(.x));
            r.columns[0].set(.z, mat.columns[2].get(.x));

            r.columns[1].set(.x, mat.columns[0].get(.y));
            r.columns[1].set(.z, mat.columns[2].get(.y));

            r.columns[2].set(.x, mat.columns[0].get(.z));
            r.columns[2].set(.y, mat.columns[1].get(.z));

            return r;
        }
    };
}

pub fn Mat4(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec4(T);

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.columns[0].set(.x, 1);
            tmp.columns[1].set(.y, 1);
            tmp.columns[2].set(.z, 1);
            tmp.columns[3].set(.w, 1);

            break :identity tmp;
        };

        columns: [4]Vector,

        pub inline fn from(c0: Vector, c1: Vector, c2: Vector, c3: Vector) Self {
            return .{ .columns = .{ c0, c1, c2, c3 } };
        }

        pub inline fn splat(element: T) Self {
            return .{ .columns = @splat(.splat(element)) };
        }

        pub fn add(a: Self, b: Self) Self {
            return from(
                a.columns[0].add(b.columns[0]),
                a.columns[1].add(b.columns[1]),
                a.columns[2].add(b.columns[2]),
                a.columns[3].add(b.columns[3]),
            );
        }

        pub fn sub(a: Self, b: Self) Self {
            return from(
                a.columns[0].sub(b.columns[0]),
                a.columns[1].sub(b.columns[1]),
                a.columns[2].sub(b.columns[2]),
                a.columns[3].sub(b.columns[3]),
            );
        }

        pub fn multiply(a: Self, b: Self) Self {
            const transposed = a.transpose();
            const ar0 = transposed.columns[0];
            const ar1 = transposed.columns[1];
            const ar2 = transposed.columns[2];
            const ar3 = transposed.columns[3];

            return from(.init(
                ar0.dot(b.columns[0]),
                ar1.dot(b.columns[0]),
                ar2.dot(b.columns[0]),
                ar3.dot(b.columns[0]),
            ), .init(
                ar0.dot(b.columns[1]),
                ar1.dot(b.columns[1]),
                ar2.dot(b.columns[1]),
                ar3.dot(b.columns[1]),
            ), .init(
                ar0.dot(b.columns[2]),
                ar1.dot(b.columns[2]),
                ar2.dot(b.columns[2]),
                ar3.dot(b.columns[2]),
            ), .init(
                ar0.dot(b.columns[3]),
                ar1.dot(b.columns[3]),
                ar2.dot(b.columns[3]),
                ar3.dot(b.columns[3]),
            ));
        }

        pub fn scale(mat: Self, scalar: T) Self {
            return from(
                mat.columns[0].scale(scalar),
                mat.columns[1].scale(scalar),
                mat.columns[2].scale(scalar),
                mat.columns[3].scale(scalar),
            );
        }

        pub fn transpose(mat: Self) Self {
            var r = mat;
            r.columns[0].set(.y, mat.columns[1].get(.x));
            r.columns[0].set(.z, mat.columns[2].get(.x));
            r.columns[0].set(.w, mat.columns[3].get(.x));

            r.columns[1].set(.x, mat.columns[0].get(.y));
            r.columns[1].set(.z, mat.columns[2].get(.y));
            r.columns[1].set(.w, mat.columns[3].get(.y));

            r.columns[2].set(.x, mat.columns[0].get(.z));
            r.columns[2].set(.y, mat.columns[1].get(.z));
            r.columns[2].set(.w, mat.columns[3].get(.z));

            r.columns[3].set(.x, mat.columns[0].get(.w));
            r.columns[3].set(.y, mat.columns[1].get(.w));
            r.columns[3].set(.z, mat.columns[2].get(.w));

            return r;
        }
    };
}
