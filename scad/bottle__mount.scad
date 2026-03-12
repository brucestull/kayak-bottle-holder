$fn = 80;

outer_width = 95.2;
inner_width = 69.8;

overall_length = 69.9 + 41.3 + 58.7;

height = 35;
transition_height = 10;
bottle_holder_height = 63 - height - transition_height;

plate_0_x = 69.9 - 1;
plate_0_y = outer_width;

plate_2_x = 58.7 - 1;
plate_2_y = outer_width;

plate_1_x = overall_length - plate_0_x - plate_2_x;
plate_1_y = inner_width;

plate_full_x = overall_length;
plate_full_y = outer_width;

size_0 = [plate_0_x, plate_0_y];
size_1 = [plate_1_x, plate_1_y];
size_2 = [plate_2_x, plate_2_y];
size_full = [plate_full_x, plate_full_y];

plate_1_translate_x = size_0[0];
plate_1_translate_y = (outer_width - inner_width) / 2;

plate_2_translate_x = size_0[0] + size_1[0];

corner_radius = 3;

// Controls smoothness of transition
num_slices = 70;   // more slices = smoother, slower preview
slice_height = transition_height / num_slices;


// --------------------
// Helpers
// --------------------
module rect_2d(sz) {
    square(sz, center = false);
}


// --------------------
// Base plate 2D profile
// --------------------
module base_plate_profile_2d() {
    union() {
        rect_2d(size_0);

        translate([plate_1_translate_x, plate_1_translate_y])
            rect_2d(size_1);

        translate([plate_2_translate_x, 0])
            rect_2d(size_2);
    }
}

module rounded_base_plate_profile_2d(r=3) {
    offset(r = r)
        offset(delta = -r)
            base_plate_profile_2d();
}


// --------------------
// Bottle holder 2D profile
// --------------------
module bottle_holder_2d() {
    rect_2d(size_full);
}

module rounded_bottle_holder_2d(r=3) {
    offset(r = r)
        offset(delta = -r)
            bottle_holder_2d();
}


// --------------------
// 3D solids
// --------------------
module base_plate_3d() {
    linear_extrude(height = height)
        rounded_base_plate_profile_2d(corner_radius);
}


// This profile gradually widens the center section in Y
// until it becomes the full rectangle.
module transition_profile_2d(t, r=3) {
    current_middle_y = inner_width + (outer_width - inner_width) * t;
    current_middle_translate_y = (outer_width - current_middle_y) / 2;

    offset(r = r)
        offset(delta = -r)
            union() {
                rect_2d(size_0);

                translate([plate_1_translate_x, current_middle_translate_y])
                    square([plate_1_x, current_middle_y], center = false);

                translate([plate_2_translate_x, 0])
                    rect_2d(size_2);
            }
}


// Stacked slices for a visually smooth transition
module transition_3d() {
    for (potato_brainz = [0 : num_slices - 1]) {
        t = potato_brainz / (num_slices - 1);

        translate([0, 0, height + potato_brainz * slice_height])
            linear_extrude(height = slice_height + 0.001)
                transition_profile_2d(t, corner_radius);
    }
}


module bottle_holder_3d() {
    translate([0, 0, height + transition_height])
        linear_extrude(height = bottle_holder_height)
            rounded_bottle_holder_2d(corner_radius);
}

translate_x = -5;
translate_y = outer_width / 2;
translate_z = 76.1;

translate_vector = [translate_x, translate_y, translate_z];

cylinder_length = overall_length + 10;
cylinder_radius = 38.1;

cylinder_size = [cylinder_length, cylinder_radius];

module special_cylinder(sz) {
    cylinder(h = sz[0], r = sz[1], center = false);
}

module three_parts() {
    union() {
        base_plate_3d();
        transition_3d();
        bottle_holder_3d();
    }
}


// --------------------
// Render
// --------------------
difference() {
    three_parts();

    translate(translate_vector) {
        rotate([0, 90, 0])
            special_cylinder(cylinder_size);
    }
}
