$fn = 40;

// ============================================================
// OVERALL PART DIMENSIONS
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


// ============================================================
// VERTICAL STACK HEIGHTS (Z)
// ============================================================
base_height = 35;
transition_band_height = 10;
total_part_height = 55;

upper_wall_height = total_part_height - base_height - transition_band_height;


// ============================================================
// CORNER ROUNDING / TRANSITION
// ============================================================
profile_corner_radius = 3;

transition_slice_count = 70;
transition_slice_height = transition_band_height / transition_slice_count;


// ============================================================
// FOOTPRINTS / SECTION PLACEMENT
// ============================================================
left_section_size   = [part_left_length, part_outer_width];
right_section_size  = [part_right_length, part_outer_width];
center_section_size = [part_center_length, part_inner_width];
full_top_size       = [part_total_length, part_outer_width];

center_section_x = left_section_size[0];
center_section_y_offset = (part_outer_width - part_inner_width) / 2;
right_section_x = left_section_size[0] + center_section_size[0];


// ============================================================
// CRADLE CUT
// ============================================================
cradle_cut_radius = 38.1;
cradle_cut_length = part_total_length + 10;

cradle_cut_bottom_z = 30;

cradle_cut_center = [
    -5,
    part_outer_width / 2,
    cradle_cut_bottom_z + cradle_cut_radius
];


// ============================================================
// CORD FEATURE PARAMETERS
// ============================================================
cord_hole_diameter = 6;
cord_z_overage = 2;

outer_edge_to_hole_center = 7;

hole_near_y = outer_edge_to_hole_center;
hole_far_y  = part_outer_width - outer_edge_to_hole_center;

hole_stern_x = 44;
hole_bow_x   = 139;

cord_hole_x_positions = [hole_stern_x, hole_bow_x];
cord_hole_y_positions = [hole_near_y, hole_far_y];

channel_z_drop = -4;
channel_x = cord_hole_diameter;
channel_y = hole_far_y - hole_near_y;
channel_z = cord_hole_diameter - channel_z_drop;


// ============================================================
// SCREW / COUNTERBORE PARAMETERS
// ============================================================
plastic_body_height = 30;

screw_hole_clearance_diameter = 3.4;
washer_clearance_diameter = 8.5;
rivet_nut_clearance_diameter = 11;

screw_head_z = 25;
screw_head_clearance_height = 5;
rivet_nut_clearance_height = 2;

screw_clearance_z_overage = 4;
screw_drop_z = -screw_clearance_z_overage / 2;

screw_hole_02_x_adjust = 15;

screw_x_positions = [
    part_left_length / 2,
    part_left_length + part_center_length + (part_right_length / 2) - screw_hole_02_x_adjust
];

screw_y = part_outer_width / 2;


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
// 2D PROFILES
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

module full_top_profile_2d() {
    rect_2d(full_top_size);
}

module rounded_full_top_profile_2d(r = profile_corner_radius) {
    rounded_shape_2d(r)
        full_top_profile_2d();
}

module transition_profile_2d(t, r = profile_corner_radius) {
    current_center_width = part_inner_width + (part_outer_width - part_inner_width) * t;
    current_center_y_offset = (part_outer_width - current_center_width) / 2;

    rounded_shape_2d(r)
        union() {
            rect_2d(left_section_size);

            translate([center_section_x, current_center_y_offset])
                rect_2d([part_center_length, current_center_width]);

            translate([right_section_x, 0])
                rect_2d(right_section_size);
        }
}


// ============================================================
// POSITIVE BODY
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

module positive_solid() {
    union() {
        base_3d();
        transition_3d();
        upper_wall_3d();
    }
}


// ============================================================
// NEGATIVE CUT HELPERS
// ============================================================
module cradle_cut() {
    translate(cradle_cut_center)
        rotate([0, 90, 0])
            cylinder(h = cradle_cut_length, r = cradle_cut_radius, center = false);
}

module cord_hole_cut(x, y) {
    translate([x, y, -cord_z_overage])
        cylinder(h = total_part_height + cord_z_overage * 2, d = cord_hole_diameter, center = false);
}

module cord_channel_cut(x) {
    translate([x - cord_hole_diameter / 2, hole_near_y, channel_z_drop])
        cube([channel_x, channel_y, channel_z], center = false);
}

module screw_clearance_cut(x) {
    translate([x, screw_y, screw_drop_z])
        cylinder(
            h = plastic_body_height + screw_clearance_z_overage,
            d = screw_hole_clearance_diameter,
            center = false
        );
}

module rivet_nut_counterbore_cut(x) {
    translate([x, screw_y, screw_drop_z])
        cylinder(
            h = rivet_nut_clearance_height - screw_drop_z,
            d = rivet_nut_clearance_diameter,
            center = false
        );
}

module screw_head_counterbore_cut(x) {
    translate([x, screw_y, screw_head_z])
        cylinder(
            h = screw_head_clearance_height + screw_clearance_z_overage,
            d = washer_clearance_diameter,
            center = false
        );
}


// ============================================================
// RUBBER FILLER POCKETS
// ============================================================
filler_pocket_offset_from_edge = 32;

filler_pocket_x_positions = [10, 30, 60, 75, 90, 105];
filler_pocket_y_positions = [filler_pocket_offset_from_edge, part_outer_width - filler_pocket_offset_from_edge];

module filler_pocket_cut(x, y) {
    translate([x, y, -.25])
    cylinder(d = 10, h = 3.75, center = false);
};

// ============================================================
// ALL NEGATIVE CUTS
// ============================================================
module all_negative_cuts() {
    cradle_cut();

    // Four vertical cord holes
    for (x = cord_hole_x_positions)
        for (y = cord_hole_y_positions)
            cord_hole_cut(x, y);

    // Two bottom cord channels
    for (x = cord_hole_x_positions)
        cord_channel_cut(x);

    // Two screw clearances + lower counterbores + upper counterbores
    for (x = screw_x_positions) {
        screw_clearance_cut(x);
        rivet_nut_counterbore_cut(x);
        screw_head_counterbore_cut(x);
    }
    for (x = filler_pocket_x_positions)
        for (y = filler_pocket_y_positions)
//            echo("Pocket location: ", x, y)
            filler_pocket_cut(x, y);
}


// ============================================================
// FINAL MODEL
// ============================================================
difference() {
    positive_solid();
    all_negative_cuts();
}