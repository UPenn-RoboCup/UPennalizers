#include <ode/ode.h>
#include <GL/gl.h>
#include <plugins/physics.h>
#include <string.h>

// saffir_phyics.c 
// refer to stewart_platform_physics.c and contact_points_physics.c for reference


#define FTS_RECEIVER_CHANNEL 10
#define MAX_CONTACTS         10
#define MAX_COP              10
#define DRAW_FOOT_CONTACTS    1


// define global variables 
static dWorldID world = NULL;
static dSpaceID space = NULL;
static dJointGroupID contact_joint_group = NULL;

// define foot / floor contact variables
enum foot {LEFT_FOOT, RIGHT_FOOT, N_FEET};
static dGeomID floor_geom = NULL;
static dGeomID foot_geom[2] = {NULL, NULL};
static dBodyID foot_body[2] = {NULL, NULL};
static int nContacts[2] = {0, 0};
static dContact foot_contacts[2][MAX_CONTACTS];
static dJointFeedback foot_feedbacks[2][MAX_CONTACTS];
static double foot_fts[2][6] = {
  {0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0},
};
static double foot_cop[MAX_COP][2];

// define foot / floor names
static const char *floor_name = "FLOOR";
static const char *foot_name[2] = {
  "L_ANKLE_P2",
  "R_ANKLE_P2",
};

// define upper piston name for each linear actuator
static const char *upper_piston_name[10] = {
  "LO_HIP",     // 0 l_hip_outer
  "LI_HIP",     // 1 l_hip_inner
  "L_KNEE",     // 2 l_knee_pitch
  "LO_ANKLE",   // 3 l_ankle_outer
  "LI_ANKLE",   // 4 l_ankle_inner
  "RO_HIP",     // 5 r_hip_outer
  "RI_HIP",     // 6 r_hip_inner
  "R_KNEE",     // 7 r_knee_pitch
  "RO_ANKLE",   // 8 r_ankle_outer
  "RI_ANKLE"    // 9 r_ankle_inner
};

// define lower piston name for each linear actuator
static const char *lower_piston_name[10] = {
  "LO_HIP.LINEARACTUATOR",   // 0
  "LI_HIP.LINEARACTUATOR",   // 1
  "L_KNEE.LINEARACTUATOR",   // 2
  "LO_ANKLE.LINEARACTUATOR", // 3
  "LI_ANKLE.LINEARACTUATOR", // 4
  "RO_HIP.LINEARACTUATOR",   // 5
  "RI_HIP.LINEARACTUATOR",   // 6
  "R_KNEE.LINEARACTUATOR",   // 7
  "RO_ANKLE.LINEARACTUATOR", // 8
  "RI_ANKLE.LINEARACTUATOR"  // 9
};

// define upper link name for each linear actuator
static const char *upper_link_name[10] = {
  "SAFFiR",       // 0
  "SAFFiR",       // 1
  "L_HIPPITCH",   // 2
  "L_KNEE_PIVOT", // 3
  "L_KNEE_PIVOT", // 4
  "SAFFiR",       // 5
  "SAFFiR",       // 6
  "R_HIPPITCH",   // 7
  "R_KNEE_PIVOT", // 8
  "R_KNEE_PIVOT"  // 9
};

// define lower link name for each linear actuator
static const char *lower_link_name[10] = {
  "L_HIPPITCH",   // 0
  "L_HIPPITCH",   // 1
  "L_KNEE_PIVOT", // 2
  "L_ANKLE_P2",   // 3
  "L_ANKLE_P2",   // 4
  "R_HIPPITCH",   // 5
  "R_HIPPITCH",   // 6
  "R_KNEE_PIVOT", // 7
  "R_ANKLE_P2",   // 8
  "R_ANKLE_P2"    // 9
};

// convenience function to print a 3d vector
void print_vec3(const char *msg, const dVector3 v) {
  dWebotsConsolePrintf("%s: %g %g %g\n", msg, v[0], v[1], v[2]);
}

// convenience function to find ODE geometry by its DEF name in the .wbt file
dGeomID getGeom(const char *def) {
  dGeomID geom = dWebotsGetGeomFromDEF(def);
  if (!geom)
    dWebotsConsolePrintf("Warning: did not find geometry with DEF name: %s", def);
  return geom;
}

// convenience function to find ODE body by its DEF name in the .wbt file
dBodyID getBody(const char *def) {
  dBodyID body = dWebotsGetBodyFromDEF(def);
  if (!body)
    dWebotsConsolePrintf("Warning: did not find body with DEF name: %s", def);
  return body;
}

// debug function for rendering foot contact points and center of pressure
void draw_foot_contacts() {

  int i, j;
  double total_pressure = 0;
  double cop_points[MAX_COP-1][2];
  for (i = MAX_COP; i > 0; i--)
    memcpy(foot_cop[i], foot_cop[i-1], 2*sizeof(double));
  memset(foot_cop[0], 0, 2*sizeof(double));

  // change OpenGL state
  glDisable(GL_LIGHTING);    // not necessary
  glLineWidth(4);            // use a thick line
  glDisable(GL_DEPTH_TEST);  // draw in front of Webots graphics

  for (i = 0; i < N_FEET; i++) {
    for (j = 0; j < nContacts[i]; j++) {
      dReal *p = foot_contacts[i][j].geom.pos;
      dReal *n = foot_contacts[i][j].geom.normal;
      dReal d = foot_contacts[i][j].geom.depth * 15;
      foot_cop[0][0] += p[0] * n[2] * d;
      foot_cop[0][1] += p[1] * n[2] * d;
      total_pressure += n[2] * d;

      // draw contact points
      glBegin(GL_LINES);
      glColor3f(0, 1, 0);  // Specify color 
      glVertex3f(p[0], p[1], p[2]);
      glVertex3f(p[0] + n[0] * d, p[1] + n[1] * d, p[2] + n[2] * d);
      glEnd();
    }
  }
  foot_cop[0][0] /= total_pressure;
  foot_cop[0][1] /= total_pressure;

  // draw center of pressure trajectory
  for (i = 0; i < MAX_COP-1; i++) {
    cop_points[i][0] = (foot_cop[i][0] + foot_cop[i+1][0])/2;
    cop_points[i][1] = (foot_cop[i][1] + foot_cop[i+1][1])/2;
  }
  glBegin(GL_LINE_STRIP);
  glColor3f(1, 1, 1);
  for (i = 0; i < MAX_COP-1; i++) 
    glVertex3f(cop_points[i][0], cop_points[i][1], 0);
  glEnd( );
}

// called by Webots at the beginning of the simulation
void webots_physics_init(dWorldID w, dSpaceID s, dJointGroupID j) {

  int i;

  // store global objects for later use
  world = w;
  space = s;
  contact_joint_group = j;

  // get floor geometry
  floor_geom = getGeom(floor_name);
  if (!floor_geom)
    return;

  // get foot geometry and body id's
  for (i = 0; i < N_FEET; i++) {
    foot_geom[i] = getGeom(foot_name[i]);
    if (!foot_geom[i])
      return;
    foot_body[i] = dGeomGetBody(foot_geom[i]);
    if (!foot_body[i])
      return;
  }

  // create universal joints for linear actuators
  for (i = 0; i < 10; i++) {
    dBodyID upper_piston = getBody(upper_piston_name[i]);
    dBodyID lower_piston = getBody(lower_piston_name[i]);
    dBodyID upper_link = getBody(upper_link_name[i]);
    dBodyID lower_link = getBody(lower_link_name[i]);
    if (!upper_piston || !lower_piston || !upper_link || !lower_link)
      return;

    // create a ball and socket joint (3 DOFs) to attach the lower piston body to the lower link 
    // we don't need a universal joint here, because the piston's passive rotation is prevented
    // by the universal joint at its upper end.
    dJointID lower_balljoint = dJointCreateBall(world, 0);
    dJointAttach(lower_balljoint, lower_piston, lower_link);

    // transform attachement point from local to global coordinate system
    // warning: this is a hard-coded translation 
    dVector3 lower_ball;
    dBodyGetRelPointPos(lower_piston, 0, 0, -0.075, lower_ball);

    // set attachement point (anchor)
    dJointSetBallAnchor(lower_balljoint, lower_ball[0], lower_ball[1], lower_ball[2]);
    
    // create a universal joint (2 DOFs) to attach upper piston body to upper link
    // we need to use a universal joint to prevent the piston from passively rotating around its long axis
    dJointID upper_ujoint = dJointCreateUniversal(world, 0);
    dJointAttach(upper_ujoint, upper_piston, upper_link);

    // transform attachement point from local to global coordinate system
    // warning: this is a hard-coded translation 
    dVector3 upper_ball;
    dBodyGetRelPointPos(upper_piston, 0, 0, 0, upper_ball);

    // set attachement point (anchor)
    dJointSetUniversalAnchor(upper_ujoint, upper_ball[0], upper_ball[1], upper_ball[2]);

    // set the universal joint axes
    dVector3 upper_xaxis;
    dVector3 upper_yaxis;
    dBodyVectorToWorld(upper_piston, 1, 0, 0, upper_xaxis);
    dBodyVectorToWorld(upper_piston, 0, 1, 0, upper_yaxis);
    dJointSetUniversalAxis1(upper_ujoint, upper_xaxis[0], upper_xaxis[1], upper_xaxis[2]);
    dJointSetUniversalAxis2(upper_ujoint, upper_yaxis[0], upper_yaxis[1], upper_yaxis[2]);

  }
}

// implemented to overide Webots collision detection,
// returns 1 if a specific collision is handled, and 0 otherwise
int webots_physics_collide(dGeomID g1, dGeomID g2) {

  static dJointID contact_joints[MAX_CONTACTS];
  
  int i, j;
  for (i = 0; i < N_FEET; i++) {
    // handle any collisions involving a foot and the floor
    if ((g1 == foot_geom[i] && g2 == floor_geom) || (g2 == foot_geom[i] && g1 == floor_geom)) {

      // see how many collision points there are between the two geometries
      nContacts[i] = dCollide(foot_geom[i], floor_geom, MAX_CONTACTS, &foot_contacts[i][0].geom, sizeof(dContact));

      for (j = 0; j < nContacts[i]; j++) {
        // custom parameters for creating the contact joint
        // remove or tune these contact parameters to suit your needs
        foot_contacts[i][j].surface.mode = dContactBounce | dContactSoftCFM | dContactApprox1;
        foot_contacts[i][j].surface.mu = 1.5;
        foot_contacts[i][j].surface.bounce = 0.5;
        foot_contacts[i][j].surface.bounce_vel = 0.01;
        foot_contacts[i][j].surface.soft_cfm = 0.001;
    
        // create a contact joint that will prevent the two bodies from intersecting
        // note that contact joints are added to the contact_joint_group
        contact_joints[j] = dJointCreateContact(world, contact_joint_group, &foot_contacts[i][j]);
    
        // attach joint between the body and the static environment (0)
        dJointAttach(contact_joints[j], foot_body[i], 0);
    
        // attach feedback structure to measure the force on the contact joint
        dJointSetFeedback(contact_joints[j], &foot_feedbacks[i][j]);
      }
      return 1;  // collision was handled above
    }
  }

  return 0;  // collision must be handled by webots
}

// called by Webots for every WorldInfo.basicTimeStep
void webots_physics_step() {
  // nothing to do ...
}

// called by Webots after dWorldStep()
void webots_physics_step_end() {

  int i,j;

  // calculate force-torque measurements for foot contacts
  for (i = 0; i < N_FEET; i++) {

    double past_fts[6];
    double filtered_fts[6];
    memcpy(past_fts, foot_fts[i], 6*sizeof(double));
    memset(foot_fts[i], 0, 6*sizeof(double));

    // sum contact forces and torques
    for (j = 0; j < nContacts[i]; j++) {
      double *f = foot_feedbacks[i][j].f1;
      double *t = foot_feedbacks[i][j].t1;
      foot_fts[i][0] += f[0];
      foot_fts[i][1] += f[1];
      foot_fts[i][2] += f[2];
      foot_fts[i][3] += t[0];
      foot_fts[i][4] += t[1];
      foot_fts[i][5] += t[2];
    }

    // average current and past measurements
    for (j = 0; j < 6; j++) {
      filtered_fts[j] = (foot_fts[i][j] + past_fts[j])/2;
    }

    // send force-torque array to Webots receiver sensor
    dWebotsSend(FTS_RECEIVER_CHANNEL + i, filtered_fts, 6*sizeof(double)); 
  }

}

// called by Webots at each graphics step
void webots_physics_draw() {

  if (DRAW_FOOT_CONTACTS)
    draw_foot_contacts();

}

// called by Webots to cleanup resources
void webots_physics_cleanup() {
  // nothing to cleanup ...
}

