$fn = 40;


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
total_part_height = 55;            // full final height

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


// `total_part_height` will be used for `block_z`
module cord_hole_solid(t_vector, hole_dia, block_z, z_overage) {
    translate(t_vector)
    cylinder(h = block_z + (z_overage * 2), d = hole_dia, center = false);
};

module cord_channel_solid(t_vector, channel_dims, z_drop = 0) {
    translate([0, 0, z_drop]) {
        translate(t_vector)
        cube(channel_dims, center = false);
    };
};

module make_screw_hole_solid(t_vector, clearance_dia) {
    translate(t_vector)

    // Screw clearance hole
    cylinder(h = plastic_body_height + screw_clearance_z_overage, d = clearance_dia, center = false);
};

module make_counterbore_hole_solid(t_vector, clearance_dia, clearance_height) {
    translate(t_vector)
    cylinder(h = clearance_height, d = clearance_dia);
};

// ============================================================
// Create cord holes in mount
// ============================================================

cord_hole_diameter = 6;

outer_edge_to_hole_center = 7;

cord_z_overage = 2;

hole_near_y = outer_edge_to_hole_center;
hole_far_y = part_outer_width - outer_edge_to_hole_center;

hole_bow_x = 139;  // Center of the hole
hole_stern_x = 44;  // Center of the hole

hole_01_translate = [hole_stern_x, hole_near_y, -cord_z_overage];
hole_02_translate = [hole_bow_x, hole_near_y, -cord_z_overage];
hole_03_translate = [hole_stern_x, hole_far_y, -cord_z_overage];
hole_04_translate = [hole_bow_x, hole_far_y, -cord_z_overage];


// ============================================================
// Create cord bottom channels
// ============================================================


// These are for the translation of the channels
channel_01_tx = hole_stern_x - (cord_hole_diameter / 2);
channel_02_tx = hole_bow_x - (cord_hole_diameter / 2);

channel_01_ty = hole_near_y;
channel_02_ty = hole_near_y;

channel_z_drop = -4;

channel_01_tz = channel_z_drop;
channel_02_tz = channel_z_drop;

channel_01_translate = [channel_01_tx, channel_01_ty, channel_01_tz];
channel_02_translate = [channel_02_tx, channel_02_ty, channel_02_tz];

// These are for the dimensions of the channels

channel_x = cord_hole_diameter;
channel_y = cord_hole_diameter;
channel_z = cord_hole_diameter - channel_z_drop;


channel_01_dims = [channel_x, hole_far_y - hole_near_y, channel_z];
channel_02_dims = [channel_x, hole_far_y - hole_near_y, channel_z];


// ============================================================
// Screw holes for mounting to kayak
// ============================================================

// These are for the dimensions of the screw holes
plastic_body_height = 30;

screw_head_z = 25;
screw_head_clearance_height = 5;
rivet_nut_clearance_height = 2;

screw_hole_clearance_diameter = 3.4;
washer_clearance_diameter = 8.5;
rivet_nut_clearance_diameter = 11;

screw_clearance_z_overage = 4;
screw_drop_z = -screw_clearance_z_overage / 2;

rivet_nut_drop_z = 2;

// These are for the translation of the screw holes

screw_hole_01_tx = part_left_length / 2;
screw_hole_01_ty = part_outer_width / 2;
screw_hole_01_tz = screw_drop_z;

screw_hole_02_x_adjust = 15;

screw_hole_02_tx = part_left_length + part_center_length + (part_right_length / 2) - screw_hole_02_x_adjust;
screw_hole_02_ty = part_outer_width / 2;
screw_hole_02_tz = screw_drop_z;

screw_hole_01_translate = [screw_hole_01_tx, screw_hole_01_ty, screw_hole_01_tz];
screw_hole_02_translate = [screw_hole_02_tx, screw_hole_02_ty, screw_hole_02_tz];


screw_head_hole_01_tx = part_left_length / 2;
screw_head_hole_01_ty = part_outer_width / 2;
screw_head_hole_01_tz = screw_head_z;

screw_head_hole_01_translate = [screw_head_hole_01_tx, screw_head_hole_01_ty, screw_head_hole_01_tz];


screw_head_hole_02_tx = part_left_length + part_center_length + (part_right_length / 2) - screw_hole_02_x_adjust;
screw_head_hole_02_ty = part_outer_width / 2;
screw_head_hole_02_tz = screw_head_z;

screw_head_hole_02_translate = [screw_head_hole_02_tx, screw_head_hole_02_ty, screw_head_hole_02_tz];


// ============================================================
// Gap filler cups
// ============================================================


// ============================================================
// Final render
// ============================================================

difference() {
    positive_solid();

    translate(cradle_cut_center) {
        rotate([0, 90, 0])
            cradle_cut_cylinder(cradle_cut_size);
    }

    // Remove verticle cylinders for paracord passage
    cord_hole_solid(hole_01_translate, cord_hole_diameter, total_part_height, cord_z_overage);
    cord_hole_solid(hole_02_translate, cord_hole_diameter, total_part_height, cord_z_overage);
    cord_hole_solid(hole_03_translate, cord_hole_diameter, total_part_height, cord_z_overage);
    cord_hole_solid(hole_04_translate, cord_hole_diameter, total_part_height, cord_z_overage);

    // Remove bottom channels for paracord passage
    cord_channel_solid(channel_01_translate, channel_01_dims);
    cord_channel_solid(channel_02_translate, channel_02_dims);

    // Remove screw clearances
    make_screw_hole_solid(screw_hole_01_translate, screw_hole_clearance_diameter);
    make_counterbore_hole_solid(screw_hole_01_translate, rivet_nut_clearance_diameter, rivet_nut_clearance_height - screw_drop_z);
    
    make_screw_hole_solid(screw_hole_02_translate, screw_hole_clearance_diameter);
    make_counterbore_hole_solid(screw_hole_02_translate, rivet_nut_clearance_diameter, rivet_nut_clearance_height - screw_drop_z);
    
    make_counterbore_hole_solid(screw_head_hole_01_translate, washer_clearance_diameter, screw_head_clearance_height + screw_clearance_z_overage);
    make_counterbore_hole_solid(screw_head_hole_02_translate, washer_clearance_diameter, screw_head_clearance_height + screw_clearance_z_overage);
}

