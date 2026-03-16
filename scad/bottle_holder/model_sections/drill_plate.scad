$fn = 40;

// ============================================================
// BASE PLATE DIMENSIONS
// ============================================================
part_outer_width = 95.2;
part_inner_width = 69.8;

part_left_length_raw   = 69.9;
part_center_length_raw = 41.3;
part_right_length_raw  = 58.7;

left_trim  = 1;
right_trim = 1;

part_left_length  = part_left_length_raw  - left_trim;
part_right_length = part_right_length_raw - right_trim;

part_total_length = part_left_length_raw + part_center_length_raw + part_right_length_raw;
part_center_length = part_total_length - part_left_length - part_right_length;

plate_thickness = 4;

// ============================================================
// CORNER ROUNDING
// ============================================================
profile_corner_radius = 3;

// ============================================================
// FOOTPRINTS / SECTION PLACEMENT
// ============================================================
left_section_size   = [part_left_length, part_outer_width];
right_section_size  = [part_right_length, part_outer_width];
center_section_size = [part_center_length, part_inner_width];

center_section_x = left_section_size[0];
center_section_y_offset = (part_outer_width - part_inner_width) / 2;
right_section_x = left_section_size[0] + center_section_size[0];

// ============================================================
// 2D HELPERS
// ============================================================
module rect_2d(sz) {
    square(sz, center = false);
}

module rounded_shape_2d(r) {
    offset(r = r)
        offset(delta = -r)
            children();
}

// ============================================================
// 2D BASE PROFILE
// ============================================================
module base_profile_2d() {
    union() {
        rect_2d(left_section_size);

        translate([center_section_x, center_section_y_offset])
            rect_2d(center_section_size);

        translate([right_section_x, 0])
            rect_2d(right_section_size);
    }
}

module rounded_base_profile_2d(r = profile_corner_radius) {
    rounded_shape_2d(r)
        base_profile_2d();
}

// ============================================================
// 3D BASE PLATE
// ============================================================
module base_3d(thickness = plate_thickness, corner_radius = profile_corner_radius) {
    linear_extrude(height = thickness)
        rounded_base_profile_2d(corner_radius);
}

// ============================================================
// EXAMPLE USAGE
// ============================================================
// base_3d();              // default 4 mm thick
// base_3d(10);            // 10 mm thick
// base_3d(6, 2);          // 6 mm thick with 2 mm corner radius



// ============================================================
// SCREW HOLE PARAMETERS
// ============================================================
screw_hole_02_x_adjust = 15;
rivet_nut_hole_dia = 5.36;

screw_x_positions = [
    part_left_length / 2,
    part_left_length + part_center_length + (part_right_length / 2) - screw_hole_02_x_adjust
];

screw_y = part_outer_width / 2;

module tall_cylinder(diameter = rivet_nut_hole_dia, height = 75) {
    translate([0, 0, -.1])
    cylinder(d = diameter, h = height, center = false);
};

// ============================================================
// DRILL TEMPLATE RIB
// ============================================================

// 15 mm wide --> 7.5 mm half-width
// 10 mm tall

rib_width = 15;
rib_height = 10 + plate_thickness;

rib_size_x = screw_x_positions[1] - screw_x_positions[0] + rib_width;

rib_dims = [rib_size_x, rib_width, rib_height];

rib_translate = [screw_x_positions[0] - (rib_width / 2), (part_outer_width / 2) - (rib_width / 2), 0];

module drill_plate_rib(t_vector, sz) {
    translate(t_vector)
    cube(sz, center = false);
};

drop_z = .1;

difference() {
    union() {
        base_3d();
        drill_plate_rib(rib_translate, rib_dims);
    };

    for (x = screw_x_positions)
        translate([x, screw_y, 0])
            tall_cylinder();
};



