
bearing_dim = [8,22,7]; // 608 PP 8x22x7mm glass ball nylon bearings
post_od = 6.5; // 6.5mm stainless rod
num_wings = 4; // 3,4,5,6,7

wall_t = 3; // general wall thickness (mm)
holder_t = 2.5; // holder wall thickness (mm)
wing_t = 0.7; // wing thickness (mm, goal is to be 2 print layers)
wing_c = 15; // clearance between hub and housing for wing fold (mm)
fin_h = 100; // height of fin extending from back of housing (mm)
spacer_h = 10; // height of spacer between wing tips (mm)
tol = 0.4; // clearance gap between fitted parts (mm)
$fn = $preview ? 32 : 128; // number of facets in a 360° arc

function inner_fit(od, looseness = 1.0) = od - tol*looseness;
function outer_fit(id, looseness = 1.0) = id + tol*looseness;

function bearing_id() = bearing_dim[0];
function bearing_od() = bearing_dim[1];
function bearing_t() = bearing_dim[2];
function stem_od() = post_od + holder_t*2;
function stem_h() = bearing_od();
function pin_od() = inner_fit(bearing_id(), 0.50);
function hub_d() = sqrt(2) * (pin_od() + wall_t*2) + wall_t*3;
function key_t() =  num_wings * wing_t + tol;

module bearing() {
  translate([0,0,-tol]) cylinder(h=bearing_t()+tol, d=bearing_od()+tol);
}

module bearing_clearance() {
  da = bearing_od() - wall_t * 0.5;
  cylinder(h=wall_t, d1=da, d2=0);
}

module build_plate(dim=220, t=0.5) {
  translate([0,0,-t/2]) cube(size=[dim,dim,t], center=true);
}

module holder() {
  od = bearing_od() + tol*2 + wall_t*2;
  c = 1; // chamfer
  t = max(stem_od()-c, bearing_t());
  translate([0,0,(t+c)]) {
    union() {
      difference() {
        scale([1,1,0.4]) sphere(d=od);
        translate([0,0,-(od/2+tol)]) cube(size=od+tol*2, center=true);
      }
      translate([0,0,-t]) {
        cylinder(h=t, d=od);
        translate([0,0,-c]) cylinder(h=1, d1=od-c*2, d2=od);
      }
    }
  }
}

module stem(hollow=true) {
  od = stem_od();
  h = stem_h();
  r = 1;
  union() {
    difference() {
      hull() {
        rotate([-90,0,0]) cylinder(h=h, d=od);
        translate([0,h,0]) rotate([-90,0,0]) cylinder(h=r, d1=od, d2=od-r*2);
        hull() {
          translate([0,h/2,-od/4+r/2]) cube([od,h,od/2-r], center=true);
          translate([0,h/2,-od/2+r/2]) cube([od-r*2,h-r*2,r], center=true);
        }
      }
      if(hollow) stem_cavity();
    }
    rotate([-90,0,0]) sphere(d=od);
  }
}

module stem_cavity() {
  h = stem_h();
  r = 1;
  union() {
    translate([0,wall_t,0]) rotate([-90,0,0]) cylinder(h=h, d=post_od+tol*2);
    translate([0,h-wall_t+r+tol,0]) rotate([-90,0,0]) cylinder(h=wall_t, d1=post_od-tol, d2=post_od+r*2);
  }
}

module fin() {
  h = fin_h;
  w = bearing_od()/2 - wall_t;
  d = wall_t/2;
  dw = wing_t;
  union() {
    hull() {
      translate([0, w/2,0]) { cylinder(h=h, d=d); translate([0,0,h]) sphere(d=d); }
      translate([0,-w,0]) { cylinder(h=h, d=d); translate([0,0,h]) sphere(d=d); }
    }
    translate([0,-w,0]) { cylinder(h=h*.9, d1=d*2.5,d2=d*2); translate([0,0,h*.9]) sphere(d=d*2); }
    translate([0,-w,0]) hull() {
      translate([0,-w*4,h+w]) sphere(d=d);
      translate([0,-w*4,h-w*2.5]) sphere(d=d);
      translate([0,   0,h-w*5]) sphere(d=d);
      translate([0, w*4,h-w*2.5]) sphere(d=d);
      translate([0, w*4,h+w]) sphere(d=d);
    }
  }
}

module housing(fin=true) {
  od = stem_od();
  stem_tr = [0,bearing_od()/2+tol,od/2];
  difference() {
    union() {
      if(fin) translate([0,bearing_od()/2-wall_t/2,tol]) fin();
      holder();
      translate(stem_tr) stem(hollow=false);
    }
    union() {
      translate([0,0,bearing_t()-tol]) bearing_clearance();
      bearing();
      translate(stem_tr) stem_cavity();
    }
  }
}

module wing(a=0, t=0.5) {
  difference() {
    rotate([0,0,a]) difference() {
      scale([1,1,t]) translate([-100.5,-106.05,0]) linear_extrude(height=1) import("wing.svg");
      translate([80.6,-15.5,-tol]) cylinder(h=t+tol*2, d=pin_od()+tol*4);
    }
    translate([0,0,-key_t()/2]) wing_key(tol=tol);
  }
}

module wing_key(tol=0) {
  r = 1.5;
  s = pin_od() + wall_t*2;
  h = key_t() + wing_t;
  d1 = s+tol*2;
  d2 = d1*sqrt(2);
  hull() {
    translate([0,0,h-r/2]) cylinder(h=r, d=d1, center=true, $fn=12);
    translate([0,0,(h-r)/2]) cylinder(h=h-r, d=d2, center=true, $fn=4);
  }
}

module hub_bearing() {
  r = 1;
  t = wall_t/2;
  da = hub_d();
  db = pin_od();
  dc = bearing_id() + (bearing_od()-bearing_id())/2;
  ha = wing_c;
  hb = bearing_t()+r;//-r-tol;
  union() {
    translate([0,0,t+t+ha+r+hb]) cylinder(h=r, d1=db, d2=db-r*2);
    translate([0,0,t+t+ha+r]) cylinder(h=hb, d=db);
    translate([0,0,t+t+ha]) cylinder(h=r, d1=db, d2=db+r*2);
    translate([0,0,t+t]) cylinder(h=ha, d=db);
    translate([0,0,t]) cylinder(h=t, d1=da, d2=dc);
    cylinder(h=t, d=da);
  }
}

module hub_key() {
  t = wall_t/2;
  d = hub_d();
  db = outer_fit(pin_od(), 1.75);
  difference() {
    union() {
      translate([0,0,t]) wing_key();
      cylinder(h=t, d=d);
    }
    translate([0,0,-tol]) cylinder(h=key_t()+t+wing_t+tol*2, d=db);
  }
}

module hub() {
  rotate([180,0,0]) hub_key();
  hub_bearing();
}
function hub_h() = 1+bearing_t()-tol+(wall_t/2)+key_t();

module hub_washer() {
  h = spacer_h;
  t = wall_t/2;
  d = hub_d();
  union() {
    difference() {
      cylinder(h=t, d=d);
      translate([0,0,-tol]) cylinder(h=t+tol*2, d=pin_od()+tol*2);
    }
    difference() {
      cylinder(h=h, d=d);
      translate([0,0,-tol]) cylinder(h=h+tol*2, d=d-wall_t);
    }
  }
}

module pin() {
  h = key_t() * 2 + spacer_h + wall_t/2;
  da = pin_od();
  db = pin_od() * 2.5;
  r = 0.5;
  union() {
    translate([0,0,wall_t+h-r*2]) cylinder(h=r*2, d2=da-r*2, d1=da);
    translate([0,0,wall_t]) cylinder(h=h-r*2, d=da);
    translate([0,0,wall_t-r]) cylinder(h=r, d2=db-r, d1=db);
    translate([0,0,r]) cylinder(h=wall_t-r*2, d=db);
    cylinder(h=r, d1=db-r, d2=db);
  }
}



module assembly() {
  n = bearing_t();
  rotate([-90,0,0]) housing();
  %translate([0,bearing_od()/2+tol*3-post_od,stem_h()*-7]) cylinder(h=stem_h()*5, d=post_od);
  %translate([0,-n*2,0]) rotate([-90,0,0]) difference() {
    bearing();
    translate([0,0,-tol*2]) cylinder(h=bearing_t()+tol*4, d=bearing_id());
  }
  translate([0,-n*6.5,0]) rotate([-90,0,0]) hub();
  %translate([0,-n*8.5,0]) rotate([90,0,0]) wing(240);
  translate([0,-n*10.75,0]) rotate([-90,0,0]) hub_washer();
  translate([0,-n*14.5,0]) rotate([-90,0,0]) pin();
}

module spread() {
  n = bearing_od()/1.25;
  r = n*(num_wings+1);
  translate([-n,n,0]) rotate([0,0,90]) housing();
  translate([n,n,0]) hub_bearing();
  translate([n,-n*3,0]) hub_washer();
  translate([n,-n,0]) hub_key();
  translate([-n,-n,0]) pin();
  for (i=[0:num_wings-1]) {
    a = i * 360/num_wings;
    translate([cos(a)*r,sin(a)*r,0]) wing(a);
  }
}

module print(item=0, build_plate=true) {
  if (item==1) housing(fin=true);
  if (item==2) hub_bearing();
  if (item==3) hub_key();
  if (item==4) hub_washer();
  if (item==5) pin();
  w = 6;
  if (item>=w && item<w+num_wings) {
    i = item - w;
    a = i * 360/num_wings;
    wing(a);
  }
  if (build_plate) %build_plate();  
}

module main(part=0) {
  if (part == -1) { spread(); }
  else if (part == 0) { assembly(); }
  else { print(part, build_plate=false); }
}

main(part=0);
