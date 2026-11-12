const std = @import("std");

const assert = std.debug.assert;
const expect = std.testing.expect;

pub fn Vec(comptime T: type, comptime len: u8) type {
    return struct {
        const Self = @This();

        pub const Vector = @Vector(len, T);

        elements: Vector = @splat(if (T == bool) false else 0),

        pub fn from(elements: Vector) Self {
            return .{ .elements = elements };
        }

        pub fn splat(element: T) Self {
            return from(@splat(element));
        }

        pub fn near(self: Self, rhs: Self, epsilon: Self) Vec(bool, len) {
            return .from(self.sub(rhs).abs().elements <= epsilon.abs().elements);
        }

        pub fn eql(self: Self, rhs: Self) Vec(bool, len) {
            return .from(self.elements == rhs.elements);
        }

        pub fn nan(self: Self) Vec(bool, len) {
            return self.eql(self);
        }

        pub fn abs(self: Self) Self {
            return from(@abs(self.elements));
        }

        pub fn add(self: Self, rhs: Self) Self {
            return from(self.elements + rhs.elements);
        }

        pub fn sub(self: Self, rhs: Self) Self {
            return from(self.elements - rhs.elements);
        }

        pub fn multiply(self: Self, rhs: Self) Self {
            return from(self.elements * rhs.elements);
        }

        pub fn scale(self: Self, element: T) Self {
            return self.multiply(splat(element));
        }

        pub fn divide(self: Self, rhs: Self) Self {
            return from(self.elements / rhs.elements);
        }

        pub fn select(self: Self, pred: Vec(bool, len), rhs: Self) Self {
            return from(@select(T, pred.elements, self.elements, rhs.elements));
        }

        pub fn shuffle(self: Self, comptime mask: Vec(i32, len)) Self {
            return from(@shuffle(T, self.elements, undefined, mask.elements));
        }

        pub fn reduce(self: Self, comptime op: std.lang.ReduceOp) T {
            return @reduce(op, self.elements);
        }

        pub fn dot(self: Self, rhs: Self) T {
            return self.multiply(rhs).reduce(.Add);
        }

        pub fn length(self: Self) T {
            return @sqrt(self.dot(self));
        }

        pub fn normalize(self: Self) Self {
            const vector = splat(self.length());
            return self.divide(splat(1).select(vector.eql(splat(0)), vector));
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

            pub fn int(self: @This()) u32 {
                return @backingInt(self);
            }
        };

        raw: Vector = .{},

        pub fn init(x: T, y: T) Self {
            return as(.{ x, y });
        }

        pub fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub fn from(elements: Vector) Self {
            return .{ .raw = elements };
        }

        pub fn get(self: Self, comptime component: Component) T {
            return self.raw.elements[comptime component.int()];
        }

        pub fn set(self: *Self, comptime component: Component, value: T) void {
            self.raw.elements[comptime component.int()] = value;
        }

        pub fn shuffle(self: Self, comptime x: Component, comptime y: Component) Self {
            return from(self.raw.shuffle(.from(.{ x.int(), y.int() })));
        }
    };
}

test "Vec2(f32).dot" {
    const V = Vec2(f32);
    const v1 = V.from(.from(.{ 4, 5 }));
    const v2 = V.from(.from(.{ 2, 9 }));
    try expect(v1.raw.dot(v2.raw) == 53);
}

test "Vec2(f32).len" {
    const v = Vec2(f32).from(.from(.{ 4, 5 }));
    try expect(v.raw.length() == @sqrt(v.raw.dot(v.raw)));
}

test "Vec2(f32).normalize" {
    const v = Vec2(f32).from(.from(.{ 4, 5 }));
    const result = v.raw.normalize();
    const expected = v.raw.scale(1 / v.raw.length());
    try expect(expected.near(result, .splat(0.0001)).reduce(.And));
}

pub fn Vec3(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Vector = Vec(T, 4);
        pub const Component = enum(u32) {
            x = 0,
            y = 1,
            z = 2,

            pub fn int(self: @This()) u32 {
                return @backingInt(self);
            }
        };

        raw: Vector = .{},

        pub fn from(elements: Vector) Self {
            var raw = elements;
            raw.elements[3] = 0;
            return .{ .raw = raw };
        }

        pub fn init(x: T, y: T, z: T) Self {
            return as(.{ x, y, z, 0 });
        }

        pub fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub fn get(self: Self, comptime component: Component) T {
            return self.raw.elements[comptime component.int()];
        }

        pub fn set(self: *Self, comptime component: Component, value: T) void {
            self.raw.elements[comptime component.int()] = value;
        }

        pub fn shuffle(self: Self, comptime x: Component, comptime y: Component, comptime z: Component) Self {
            return .{ .raw = self.raw.shuffle(.from(.{ x.int(), y.int(), z.int(), 3 })) };
        }

        pub fn cross(self: Self, rhs: Self) Self {
            const result = self.shuffle(.y, .z, .x).raw.multiply(rhs.shuffle(.z, .x, .y).raw);
            return .{ .raw = result.sub(self.shuffle(.z, .x, .y).raw.multiply(rhs.shuffle(.y, .z, .x).raw)) };
        }

        pub fn getQuaternion(self: Self, radians: T) Quaternion(T) {
            const length = self.raw.length();
            return if (length == 0) .identity else quaternion: {
                const half_radians = radians * 0.5;
                var quaternion = Quaternion(T).from(self.raw.scale(@sin(half_radians) / self.raw.length()));
                quaternion = quaternion.shuffle(.z, .w, .x, .y);
                quaternion.set(.w, @cos(half_radians));

                break :quaternion quaternion;
            };
        }

        pub fn rotate(self: Self, quaternion: Quaternion(T)) Self {
            return quaternion.mul(.from(0, self)).mul(quaternion.inverse()).v();
        }
    };
}

test "Vec3(f32).cross" {
    const V = Vec3(f32);
    const v1 = V.init(1, 0, 0);
    const v2 = V.init(0, 1, 0);
    const v = v1.cross(v2);
    try expect(v.raw.eql(.from(.{ 0, 0, 1, 0 })).reduce(.And));
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

            pub fn int(self: @This()) u32 {
                return @backingInt(self);
            }
        };

        raw: Vector = .{},

        pub fn from(elements: Vector) Self {
            return .{ .raw = elements };
        }

        pub fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub fn init(x: T, y: T, z: T, w: T) Self {
            return as(.{ x, y, z, w });
        }

        pub fn get(self: Self, comptime component: Component) T {
            return self.raw.elements[comptime component.int()];
        }

        pub fn set(self: *Self, comptime component: Component, value: T) void {
            self.raw.elements[comptime component.int()] = value;
        }

        pub fn shuffle(self: Self, comptime x: Component, comptime y: Component, comptime z: Component, comptime w: Component) Self {
            return from(self.raw.shuffle(.from(.{ x.int(), y.int(), z.int(), w.int() })));
        }

        pub fn lerp(self: Self, target: Self, t: T) Self {
            return from(self.raw.scale(1 - t).add(target.raw.scale(t)));
        }
    };
}

pub fn Mat2(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.columns[0].raw[0] = 1;
            tmp.columns[1].raw[1] = 1;

            break :identity tmp;
        };

        columns: [2]Vec2(T) = @splat(0),

        pub fn splat(scalar: T) Self {
            return .{ .columns = @splat(scalar) };
        }

        pub fn add(self: Self, rhs: Self) Self {
            return .{
                .columns = .{
                    self.columns[0].add(rhs.columns[0]),
                    self.columns[1].add(rhs.columns[1]),
                },
            };
        }

        pub fn sub(self: Self, rhs: Self) Self {
            return .{
                .columns = .{
                    self.columns[0].sub(rhs.columns[0]),
                    self.columns[1].sub(rhs.columns[1]),
                },
            };
        }

        pub fn transpose(self: Self) Self {
            var result = self;
            result.columns[0].raw[1] = self.columns[1].raw[0];
            result.columns[1].raw[0] = self.columns[0].raw[1];
        }
    };
}

pub fn Mat3(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.columns[0].data[0] = 1;
            tmp.columns[1].data[1] = 1;
            tmp.columns[2].data[2] = 1;

            break :identity tmp;
        };

        columns: [3]Vec3(T) = @splat(0),

        pub fn splat(scalar: T) Self {
            return .{ .columns = @splat(scalar) };
        }

        pub fn add(self: Self, rhs: Self) Self {
            return .{
                .columns = .{
                    self.columns[0].add(rhs.columns[0]),
                    self.columns[1].add(rhs.columns[1]),
                    self.columns[2].add(rhs.columns[2]),
                },
            };
        }

        pub fn sub(self: Self, rhs: Self) Self {
            return .{
                .columns = .{
                    self.columns[0].sub(rhs.columns[0]),
                    self.columns[1].sub(rhs.columns[1]),
                    self.columns[2].sub(rhs.columns[2]),
                },
            };
        }
    };
}

pub fn Mat4(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const identity = identity: {
            var tmp = splat(0);
            tmp.columns[0].data[0] = 1;
            tmp.columns[1].data[1] = 1;
            tmp.columns[2].data[2] = 1;
            tmp.columns[3].data[3] = 1;

            break :identity tmp;
        };

        columns: [4]Vec4(T) = @splat(0),

        pub fn splat(scalar: T) Self {
            return .{ .columns = @splat(scalar) };
        }

        pub fn add(self: Self, rhs: Self) Self {
            return .{
                .columns = .{
                    self.columns[0].add(rhs.columns[0]),
                    self.columns[1].add(rhs.columns[1]),
                    self.columns[2].add(rhs.columns[2]),
                    self.columns[3].add(rhs.columns[3]),
                },
            };
        }

        pub fn sub(self: Self, rhs: Self) Self {
            return .{
                .columns = .{
                    self.columns[0].sub(rhs.columns[0]),
                    self.columns[1].sub(rhs.columns[1]),
                    self.columns[2].sub(rhs.columns[2]),
                    self.columns[3].sub(rhs.columns[3]),
                },
            };
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

            pub fn int(self: @This()) u32 {
                return @backingInt(self);
            }
        };

        pub const identity = identity: {
            var tmp = Self{};
            tmp.set(.w, 1);

            break :identity tmp;
        };

        raw: Vector = .{},

        pub fn from(elements: Vector) Self {
            return .{ .raw = elements };
        }

        pub fn as(elements: Vector.Vector) Self {
            return from(.from(elements));
        }

        pub fn init(w: T, x: T, y: T, z: T) Self {
            return as(.{ w, x, y, z });
        }

        pub fn getVector(self: Self) Vec3(T) {
            return .from(self.shuffle(.x, .y, .z, .w).raw);
        }

        pub fn get(self: Self, comptime component: Component) T {
            return self.raw.elements[comptime component.int()];
        }

        pub fn set(self: *Self, comptime component: Component, value: T) void {
            self.raw.elements[comptime component.int()] = value;
        }

        pub fn shuffle(self: Self, comptime w: Component, comptime x: Component, comptime y: Component, comptime z: Component) Self {
            return from(self.raw.shuffle(.from(.{ w.int(), x.int(), y.int(), z.int() })));
        }

        pub fn mul(self: Self, rhs: Self) Self {
            const w2 = rhs.get(.w);
            const w1 = self.get(.w);
            const v2 = rhs.getVector();
            const v1 = self.getVector();

            const vector = v2.raw.scale(w1).add(v1.raw.scale(w2));
            var result = from(vector.add(v1.cross(v2)));
            result.shuffle(.z, .w, .x, .y);
            result.set(.w, (w1 * w2) - v1.raw.dot(v2.raw));

            return result;
        }

        pub fn conjugate(self: Self) Self {
            return from(self.raw.multiply(.from(.{ 1, -1, -1, -1 })));
        }

        pub fn inverse(self: Self) Self {
            const vector = Vector.splat(self.raw.dot());
            const selector = vector.eql(.splat(0));
            const numerator = identity.raw.select(selector, self.conjugate().raw);

            return from(numerator.divide(Vector.splat(1).select(selector, vector)));
        }
    };
}
