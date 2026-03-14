$fn = 80;


// ============================================================
// Overall part dimensions
// ============================================================
part_outer_width = 95.2;     // full outside width in Y
part_inner_width = 69.8;     // narrowed center width in Y

part_left_length   = 69.9 - 1;
part_center_length = 41.3 + 1 + 1;   // derived below if preferred
part_right_length  = 58.7 - 1;

part_total_length = 69.9 + 41.3 + 58.7;


// ============================================================
// Vertical stack heights (Z)
// ============================================================
base_height = 35;                  // lower base section
transition_band_height = 10;       // widening transition zone
total_part_height = 63;            // full final height

upper_wall_height = total_part_height - base_height - transition_band_height;
// = 18


// ============================================================
// Horizontal footprint sections (XY)
// ============================================================
left_section_size = [69.9 - 1, part_outer_width];
right_section_size = [58.7 - 1, part_outer_width];

center_section_length = part_total_length - left_section_size[0] - right_section_size[0];
center_section_size_narrow = [center_section_length, part_inner_width];

full_top_rectangle_size = [part_total_length, part_outer_width];


// ============================================================
// Section placement in XY
// ============================================================
center_section_x = left_section_size[0];
center_section_y_narrow_offset = (part_outer_width - part_inner_width) / 2;

right_section_x = left_section_size[0] + center_section_size_narrow[0];


// ============================================================
// Corner rounding
// ============================================================
profile_corner_radius = 3;


// ============================================================
// Transition smoothness
// ============================================================
transition_slice_count = 70;
transition_slice_height = transition_band_height / transition_slice_count;


// ============================================================
// Bottle cradle cylinder cut
// ============================================================
cradle_cut_radius = 38.1;
cradle_cut_length = part_total_length + 10;

// where the *bottom* of the cylinder first appears in Z
cradle_cut_bottom_z = 30;

// cylinder center position
cradle_cut_center_x = -5;
cradle_cut_center_y = part_outer_width / 2;
cradle_cut_center_z = cradle_cut_bottom_z + cradle_cut_radius;

cradle_cut_center = [
    cradle_cut_center_x,
    cradle_cut_center_y,
    cradle_cut_center_z
];

cradle_cut_size = [cradle_cut_length, cradle_cut_radius];


// ============================================================
// Helpers
// ============================================================
module rect_2d(sz) {
    square(sz, center = false);
}


// ============================================================
// Base footprint profile (narrow center)
// ============================================================
module base_profile_2d() {
    union() {
        rect_2d(left_section_size);

        translate([center_section_x, center_section_y_narrow_offset])
            rect_2d(center_section_size_narrow);

        translate([right_section_x, 0])
            rect_2d(right_section_size);
    }
}

module rounded_base_profile_2d(r = profile_corner_radius) {
    offset(r = r)
        offset(delta = -r)
            base_profile_2d();
}


// ============================================================
// Full-width top profile
// ============================================================
module full_top_profile_2d() {
    rect_2d(full_top_rectangle_size);
}

module rounded_full_top_profile_2d(r = profile_corner_radius) {
    offset(r = r)
        offset(delta = -r)
            full_top_profile_2d();
}


// ============================================================
// Transition profile
// Gradually widens the center section from inner width to outer width
// ============================================================
module transition_profile_2d(t, r = profile_corner_radius) {
    current_center_width = part_inner_width + (part_outer_width - part_inner_width) * t;
    current_center_y_offset = (part_outer_width - current_center_width) / 2;

    offset(r = r)
        offset(delta = -r)
            union() {
                rect_2d(left_section_size);

                translate([center_section_x, current_center_y_offset])
                    square([center_section_size_narrow[0], current_center_width], center = false);

                translate([right_section_x, 0])
                    rect_2d(right_section_size);
            }
}


// ============================================================
// 3D solids
// ============================================================
module base_3d() {
    linear_extrude(height = base_height)
        rounded_base_profile_2d();
}

module transition_3d() {
    for (slice_index = [0 : transition_slice_count - 1]) {
        t = slice_index / (transition_slice_count - 1);

        translate([0, 0, base_height + slice_index * transition_slice_height])
            linear_extrude(height = transition_slice_height + 0.001)
                transition_profile_2d(t);
    }
}

module upper_wall_3d() {
    translate([0, 0, base_height + transition_band_height])
        linear_extrude(height = upper_wall_height)
            rounded_full_top_profile_2d();
}

module cradle_cut_cylinder(sz) {
    cylinder(h = sz[0], r = sz[1], center = false);
}

module positive_solid() {
    union() {
        base_3d();
        transition_3d();
        upper_wall_3d();
    }
}


// ============================================================
// Final render
// ============================================================
difference() {
    positive_solid();

    translate(cradle_cut_center) {
        rotate([0, 90, 0])
            cradle_cut_cylinder(cradle_cut_size);
    }
}
