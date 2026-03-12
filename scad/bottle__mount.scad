$fn = 80;

outer_width = 95.2;
inner_width = 69.8;

overall_length = 69.9 + 41.3 + 58.7;

height = 35;
transition_height = 10;
bottle_holder_height = 63 - height - transition_height;

section_0_x = 69.9 - 1;
section_0_y = outer_width;

section_2_x = 58.7 - 1;
section_2_y = outer_width;

section_1_x = overall_length - section_0_x - section_2_x;
section_1_y = inner_width;

plate_full_x = overall_length;
plate_full_y = outer_width;

size_0 = [section_0_x, section_0_y];
size_1 = [section_1_x, section_1_y];
size_2 = [section_2_x, section_2_y];
size_full = [plate_full_x, plate_full_y];

section_1_cyl_translate_x = size_0[0];
section_1_cyl_translate_y = (outer_width - inner_width) / 2;

section_2_cyl_translate_x = size_0[0] + size_1[0];

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

        translate([section_1_cyl_translate_x, section_1_cyl_translate_y])
            rect_2d(size_1);

        translate([section_2_cyl_translate_x, 0])
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
    current_middle_cyl_translate_y = (outer_width - current_middle_y) / 2;

    offset(r = r)
        offset(delta = -r)
            union() {
                rect_2d(size_0);

                translate([section_1_cyl_translate_x, current_middle_cyl_translate_y])
                    square([section_1_x, current_middle_y], center = false);

                translate([section_2_cyl_translate_x, 0])
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

cyl_translate_x = -5;
cyl_translate_y = outer_width / 2;
cyl_translate_z = 76.1;

cyl_translate_vector = [cyl_translate_x, cyl_translate_y, cyl_translate_z];

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

    translate(cyl_translate_vector) {
        rotate([0, 90, 0])
            special_cylinder(cylinder_size);
    }
}
