const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/21_sample.txt");
const input = @embedFile("inputs/21.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const ArrayList = std.ArrayList;
const BufSet = std.BufSet;
const StringHashMap = std.StringHashMap;

const Food = struct {
    allergens: ArrayList([]const u8),
    ingredients: ArrayList([]const u8),
};

const Answers = struct {
    part1: usize,
    part2: []const u8,
};

fn answers(allocator: *mem.Allocator) !Answers {
    var foods = ArrayList(Food).init(allocator);
    defer foods.deinit();
    var allergen_to_ingredients = StringHashMap(BufSet).init(allocator);
    defer allergen_to_ingredients.deinit();
    var allergens = BufSet.init(allocator);
    defer allergens.deinit();

    var lines = mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        var food_ingredients = ArrayList([]const u8).init(allocator);
        // defer food_ingredients.deinit();
        var food_allergens = ArrayList([]const u8).init(allocator);
        // defer food_allergens.deinit();

        const i_stop_ingredients = mem.lastIndexOf(u8, line, "(").? - 1;
        var words = mem.tokenize(line[0..i_stop_ingredients], " ");
        while (words.next()) |ing| {
            try food_ingredients.append(ing); // TODO: memory leak
        }

        words = mem.tokenize(line[i_stop_ingredients + 11 ..], ", )");
        while (words.next()) |all| {
            try food_allergens.append(all); // TODO: memory leak
            try allergens.put(all);
        }

        try foods.append(Food{
            .ingredients = food_ingredients,
            .allergens = food_allergens,
        });

        // update allergen_to_ingredients with all the allergens found in this food
        for (food_allergens.items) |allergen| {
            if (allergen_to_ingredients.get(allergen) == null) {
                var set = BufSet.init(allocator);
                for (food_ingredients.items) |ingredient| {
                    try set.put(ingredient); // TODO: memory leak
                }
                try allergen_to_ingredients.put(allergen, set);
            } else {
                var set = allergen_to_ingredients.get(allergen).?;
                var intersection = BufSet.init(allocator);
                for (food_ingredients.items) |ingredient| {
                    if (set.exists(ingredient)) {
                        try intersection.put(ingredient); // TODO: memory leak
                    }
                }
                try allergen_to_ingredients.put(allergen, intersection);
            }
        }
    }

    const part1 = try ingredientsWithNoAllergens(allocator, &foods, &allergen_to_ingredients);
    const part2 = try canonicalDangerousIngredientList(allocator, &allergen_to_ingredients, &allergens);
    return Answers{ .part1 = part1, .part2 = part2 };
}

/// Figure out which ingredient contains which allergen.
/// Very messy, but it works.
fn canonicalDangerousIngredientList(allocator: *mem.Allocator, allergen_to_ingredients: *StringHashMap(BufSet), allergens: *BufSet) ![]const u8 {
    // The problem says that each allergen is found in exactly one ingredient
    var ingredient_to_allergen = StringHashMap([]const u8).init(allocator);
    defer ingredient_to_allergen.deinit();

    var it = allergen_to_ingredients.iterator();
    while (ingredient_to_allergen.count() < allergen_to_ingredients.count()) {
        // keep iterating on allergen_to_ingredients. Reset the iterator if necessary.
        const entry = blk: {
            const maybe_entry = it.next();
            if (maybe_entry != null) {
                break :blk maybe_entry.?;
            } else {
                it.index = 0;
                break :blk it.next().?;
            }
        };
        const allergen = entry.key;
        const set_ingredients = entry.value;

        var it_ingr = set_ingredients.iterator();
        if (set_ingredients.count() == 1) {
            const ingredient = it_ingr.next().?.key;
            try ingredient_to_allergen.put(ingredient, allergen);
        } else {
            var candidates = ArrayList([]const u8).init(allocator);
            // var intersection = BufSet.init(allocator);
            while (it_ingr.next()) |e| {
                const ingredient = e.key;
                if (ingredient_to_allergen.get(ingredient) == null) {
                    try candidates.append(ingredient);
                }
            }
            if (candidates.items.len == 1) {
                const ingredient = candidates.items[0];
                try ingredient_to_allergen.put(ingredient, allergen);
            }
        }
    }

    // All this mess only to sort a hash map by key :-/
    var list_allergens = ArrayList([]const u8).init(allocator);
    defer list_allergens.deinit();

    var it_all = allergens.iterator();
    while (it_all.next()) |e| {
        try list_allergens.append(e.key);
    }
    std.sort.sort([]const u8, list_allergens.items, {}, comptime utils.lessThan);

    var s = try fmt.allocPrint(allocator, "", .{});
    for (list_allergens.items) |allergen| {
        var ita = ingredient_to_allergen.iterator();
        while (ita.next()) |e| {
            if (mem.eql(u8, e.value, allergen)) {
                // log.debug("ingredient {} => allergen {}", .{ e.key, e.value });
                s = try fmt.allocPrint(allocator, "{},{}", .{ s, e.key });
            }
        }
    }
    return s[1..];
}

/// Find how many ingredients do not contain any of the listed allergens.
fn ingredientsWithNoAllergens(allocator: *mem.Allocator, foods: *ArrayList(Food), allergen_to_ingredients: *StringHashMap(BufSet)) !usize {
    var ingredients_with_allergens = BufSet.init(allocator);
    defer ingredients_with_allergens.deinit();

    var it = allergen_to_ingredients.iterator();
    while (it.next()) |e| {
        const allergen = e.key;
        // log.debug("ingredients containing {}", .{allergen});
        var set_of_ingredients = e.value;
        var it2 = set_of_ingredients.iterator();
        while (it2.next()) |entry| {
            const ingredient = entry.key;
            //     if (set_of_ingredients.count() == 1) {
            //     log.debug("{} contains {}", .{ingredient, allergen});
            // }
            // log.debug("{}", .{ingredient});
            try ingredients_with_allergens.put(ingredient);
        }
    }

    var count: usize = 0;
    for (foods.items) |food| {
        for (food.ingredients.items) |ingredient| {
            if (!ingredients_with_allergens.exists(ingredient)) {
                // log.debug("ingredient: {}", .{ingredient});
                count += 1;
            }
        }
    }
    return count;
}

fn answer2(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a = try answers(&arena.allocator);
    log.info("Part 1: {}", .{a.part1});
    log.info("Part 2: {}", .{a.part2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 21 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "ingredientsWithNoAllergens()" {
    // mxmxvkd kfcds sqjhc nhms (contains dairy, fish)
    var ingr_1 = ArrayList([]const u8).init(testing.allocator);
    defer ingr_1.deinit();
    try ingr_1.append("mxmxvkd");
    try ingr_1.append("kfcds");
    try ingr_1.append("sqjhc");
    try ingr_1.append("nhms");

    var all_1 = ArrayList([]const u8).init(testing.allocator);
    defer all_1.deinit();
    try all_1.append("dairy");
    try all_1.append("fish");

    const food_1 = Food{ .allergens = all_1, .ingredients = ingr_1 };

    // trh fvjkl sbzzf mxmxvkd (contains dairy)
    var ingr_2 = ArrayList([]const u8).init(testing.allocator);
    defer ingr_2.deinit();
    try ingr_2.append("trh");
    try ingr_2.append("fvjkl");
    try ingr_2.append("sbzzf");
    try ingr_2.append("mxmxvkd");

    var all_2 = ArrayList([]const u8).init(testing.allocator);
    defer all_2.deinit();
    try all_2.append("dairy");

    const food_2 = Food{ .allergens = all_2, .ingredients = ingr_2 };

    // sqjhc fvjkl (contains soy)
    var ingr_3 = ArrayList([]const u8).init(testing.allocator);
    defer ingr_3.deinit();
    try ingr_3.append("sqjhc");
    try ingr_3.append("fvjkl");

    var all_3 = ArrayList([]const u8).init(testing.allocator);
    defer all_3.deinit();
    try all_3.append("soy");

    const food_3 = Food{ .allergens = all_3, .ingredients = ingr_3 };

    // sqjhc mxmxvkd sbzzf (contains fish)
    var ingr_4 = ArrayList([]const u8).init(testing.allocator);
    defer ingr_4.deinit();
    try ingr_4.append("sqjhc");
    try ingr_4.append("mxmxvkd");
    try ingr_4.append("sbzzf");

    var all_4 = ArrayList([]const u8).init(testing.allocator);
    defer all_4.deinit();
    try all_4.append("fish");

    const food_4 = Food{ .allergens = all_4, .ingredients = ingr_4 };

    var foods = ArrayList(Food).init(testing.allocator);
    defer foods.deinit();
    try foods.append(food_1);
    try foods.append(food_2);
    try foods.append(food_3);
    try foods.append(food_4);

    var allergen_to_ingredients = StringHashMap(BufSet).init(testing.allocator);
    defer allergen_to_ingredients.deinit();
    var dairy_set = BufSet.init(testing.allocator);
    defer dairy_set.deinit();
    try dairy_set.put("mxmxvkd");
    var fish_set = BufSet.init(testing.allocator);
    defer fish_set.deinit();
    try fish_set.put("mxmxvkd");
    try fish_set.put("sqjhc");
    var soy_set = BufSet.init(testing.allocator);
    defer soy_set.deinit();
    try soy_set.put("sqjhc");
    try soy_set.put("fvjkl");

    try allergen_to_ingredients.put("dairy", dairy_set);
    try allergen_to_ingredients.put("fish", fish_set);
    try allergen_to_ingredients.put("soy", soy_set);

    const n = try ingredientsWithNoAllergens(testing.allocator, &foods, &allergen_to_ingredients);
    testing.expectEqual(@intCast(usize, 5), n);
}
