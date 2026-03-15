height_00 = 00;
height_02 = 02;
height_04 = 04;
height_06 = 06;
height_08 = 08;

heights = [
    height_00,
    height_02,
    height_04,
    height_06,
    height_08,
];

lengths = [
    0,
    20,
    40,
    60,
    80
];

 H = 32;
 W = 50;
 
 eps = .001;
 
 linear_extrude(3) {
    translate([0, H + height_06 - eps, 0]) {
        square([W + lengths[4], 2], center = false);
    };
    translate([0, H + height_04 - eps, 0]) {
        square([W + lengths[3], 2], center = false);
    };
    translate([0, H + height_02 - eps, 0]) {
        square([W + lengths[2], 2], center = false);
    };
    translate([0, H - eps, 0]) {
        square([W + lengths[1], 2], center = false);
    };
    square([W, H], center = false);
};
