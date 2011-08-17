/*
 * File:          
 * Date:          
 * Description:   
 * Author:        
 * Modifications: 
 */

#include <ode/ode.h>
#include <plugins/physics.h>
#include <stdio.h>
/*
#include <time.h>
*/
#define PARTS_NUMBER 21

/* Define our Global Variables */
static dGeomID geoms[PARTS_NUMBER]; // Geometries for collision checking
static dGeomID ballGeom; // Geometries for collision checking
static dGeomID fieldGeom; // Geometries for collision checking

static dBodyID ballBody; // Body for velocity setting

/* The general variables from ODE. */
static dWorldID world;
static dSpaceID space;
static dJointGroupID contact_joint_group;

/* Initial time */
/*
time_t t0;
*/
/* Initial Ball variables */
double bx0, by0, bz0, bvx0, bvy0, bvz0;

/*
 * Note: This plugin will become operational only after it was compiled and associated with the current world (.wbt).
 * To associate this plugin with the world follow these steps:
 *  1. In the Scene Tree, expand the "WorldInfo" node and select its "physics" field
 *  2. Then hit the [...] button at the bottom of the Scene Tree
 *  3. In the list choose the name of this plugin (same as this file without the extention)
 *  4. Then save the .wbt by hitting the "Save" button in the toolbar of the 3D view
 *  5. Then revert the simulation: the plugin should now load and execute with the current simulation
 */

void webots_physics_init(dWorldID w, dSpaceID s, dJointGroupID j) {

  dWebotsConsolePrintf("Initializing ball collision physics engine...\n");
/*
  t0 = time(NULL);
*/
  // Assign the ODE Vars
  world = w;
  space = s;
  contact_joint_group = j;

  /*
   * Get ODE object from the .wbt model, e.g.
   *   dBodyID body1 = dWebotsGetBodyFromDEF("MY_ROBOT");
   *   dBodyID body2 = dWebotsGetBodyFromDEF("MY_SERVO");
   *   dGeomID geom2 = dWebotsGetGeomFromDEF("MY_SERVO");
   * If an object is not found in the .wbt world, the function returns NULL.
   * Your code should correcly handle the NULL cases because otherwise a segmentation fault will crash Webots.
   *
   * This function is also often used to add joints to the simulation, e.g.
   *   dJointID joint = dJointCreateBall(world, 0);
   *   dJointAttach(joint, body1, body2);
   *   ...
   */

  // Get the DARwIn-OP Geometries
  geoms[0] = dWebotsGetGeomFromDEF("DARwIn-OP"); // Space

  // Head Motors
  geoms[1] = dWebotsGetGeomFromDEF("Neck");
  geoms[2] = dWebotsGetGeomFromDEF("Head");

  // Left Leg
  geoms[3] = dWebotsGetGeomFromDEF("PelvYL");
  geoms[4] = dWebotsGetGeomFromDEF("PelvL");
  geoms[5] = dWebotsGetGeomFromDEF("LegUpperL");
  geoms[6] = dWebotsGetGeomFromDEF("LegLowerL"); // Space
  geoms[7] = dWebotsGetGeomFromDEF("AnkleL");
  geoms[8] = dWebotsGetGeomFromDEF("FootL");

  // Right Leg
  geoms[9] = dWebotsGetGeomFromDEF("PelvYR");
  geoms[10] = dWebotsGetGeomFromDEF("PelvR");
  geoms[11] = dWebotsGetGeomFromDEF("LegUpperR");
  geoms[12] = dWebotsGetGeomFromDEF("LegLowerR"); // Space
  geoms[13] = dWebotsGetGeomFromDEF("AnkleR");
  geoms[14] = dWebotsGetGeomFromDEF("FootR");

  // Left arm
  geoms[15] = dWebotsGetGeomFromDEF("ShoulderL");
  geoms[16] = dWebotsGetGeomFromDEF("ArmUpperL");
  geoms[17] = dWebotsGetGeomFromDEF("ArmLowerL");

  // Right arm
  geoms[18] = dWebotsGetGeomFromDEF("ShoulderR");
  geoms[19] = dWebotsGetGeomFromDEF("ArmUpperR");
  geoms[20] = dWebotsGetGeomFromDEF("ArmLowerR");


  // Others
  //geoms[13] = dWebotsGetGeomFromDEF("BodyShape");  

  // Ball Geometry
  ballGeom = dWebotsGetGeomFromDEF("BALL");
  fieldGeom = dWebotsGetGeomFromDEF("FIELD");
  
/*  
  dWebotsConsolePrintf("Ball ID: %d\n", ballGeom);
  dWebotsConsolePrintf("Field ID: %d\n", fieldGeom);
  int i;
  for (i = 0; i < PARTS_NUMBER; i++) {
    dWebotsConsolePrintf("Body ID: %d\n", geoms[i]);      
  }
*/

  dWebotsConsolePrintf("Reading initial ball parameters for this trial...\n");

  FILE* ball_params = fopen("/Users/stephen/Desktop/dodgeball_sim/ball_params.txt","r");
  fscanf(ball_params,"%lf %lf %lf",&bx0,&by0,&bz0);
  fscanf(ball_params,"%lf %lf %lf",&bvx0,&bvy0,&bvz0);

  // Get Ball Body
  ballBody = dWebotsGetBodyFromDEF("BALL");
  // Set the Ball's initial position
  dBodySetPosition( ballBody, bx0, by0, bz0 );
  // Start the ball moving
  //dBodySetLinearVel(ballBody, bvx0, bvy0, bvz0);
  dBodyAddForce(ballBody, 0.01,-1,0.01);

}

void webots_physics_step() {
  static int toSetVel = 0;
  static int count = 0;
  count++;
  // Set the vel
  if( count == 200 ){
    toSetVel = 1;   
  }
  if( toSetVel==1 ){
//    dBodySetPosition ( ballBody, bx0,  by0,  bz0 );
//    dBodySetLinearVel( ballBody, bvx0, bvy0, bvz0);
//    dBodyAddForce(ballBody, -3,0,0);
    dBodyAddForce( ballBody, bvx0, bvy0, bvz0);

    dWebotsConsolePrintf("Setting velocity: %lf %lf %lf\n",bvx0, bvy0, bvz0);
    toSetVel = 0;
  } else {
    //dBodySetLinearVel(ballBody, 0, 0, 0);
  }
  /*
   * Do here what needs to be done at every time step, e.g. add forces to bodies
   *   dBodyAddForce(body1, f[0], f[1], f[2]);
   *   ...
   */

  
}

void webots_physics_draw() {
  /*
   * This function can optionally be used to add OpenGL graphics to the 3D view, e.g.
   *   // setup draw style
   *   glDisable(GL_LIGHTING);
   *   glLineWidth(2);
   * 
   *   // draw a yellow line
   *   glBegin(GL_LINES);
   *   glColor3f(1, 1, 0);
   *   glVertex3f(0, 0, 0);
   *   glVertex3f(0, 1, 0);
   *   glEnd();
   */
}

int webots_physics_collide(dGeomID g1, dGeomID g2) {

/*
    dWebotsConsolePrintf("G1 part: %d\n",g1);
    dWebotsConsolePrintf("G2 part: %d\n",g2);
*/

  /*
   * This function needs to be implemented if you want to overide Webots collision detection.
   * It must return 1 if the collision was handled and 0 otherwise. 
   * Note that contact joints should be added to the contactJointGroup, e.g.
   *   n = dCollide(g1, g2, MAX_CONTACTS, &contact[0].geom, sizeof(dContact));
   *   ...
   *   dJointCreateContact(world, contactJointGroup, &contact[i])
   *   dJointAttach(contactJoint, body1, body2);
   *   ...
   */

  /* Taken directly from shrimp.c */
  int g1_robot_part, g2_robot_part, i, ballSpaceCollide;

  g1_robot_part = 0;
  g2_robot_part = 0;
  ballSpaceCollide = 0;

  /*
   * First of all, we need to detect whether or not the colliding geoms
   * are from our robot.
   */
  for (i = 0; i < PARTS_NUMBER; i++) {
/*
    dWebotsConsolePrintf("G1 part: %d\n",g1_robot_part);
    dWebotsConsolePrintf("G2 part: %d\n",g1_robot_part);
*/
    if (dGeomIsSpace(geoms[i])) {
/*
      dWebotsConsolePrintf("Item %d is a space.\n",i);
*/
      if (g1_robot_part != 1) {
        g1_robot_part = dSpaceQuery((dSpaceID) geoms[i], g1);
      }
      if (g2_robot_part != 1) {
        g2_robot_part = dSpaceQuery((dSpaceID) geoms[i], g2);
      }

      if(g1==ballGeom){
        ballSpaceCollide = dSpaceQuery((dSpaceID) geoms[i], g1);
      } else if(g2==ballGeom){
        ballSpaceCollide = dSpaceQuery((dSpaceID) geoms[i], g2);
      }
      if( ballSpaceCollide!=0 ){
        dWebotsConsolePrintf("Space Collide: %d\n", ballSpaceCollide);        
      }

      
    } else {
/*
      dWebotsConsolePrintf("G1: %d\n",g1);
      dWebotsConsolePrintf("G2: %d\n",g2);
      dWebotsConsolePrintf("DARwIn-OP Part: %d\n",geoms[i]);
*/
      if (g1_robot_part != 1) {
        g1_robot_part = (g1 == geoms[i]);
      }
      if (g2_robot_part != 1) {
        g2_robot_part = (g2 == geoms[i]);
      }

      if( g1==ballGeom && g2==geoms[i] ){
        dWebotsConsolePrintf("Part %d collided with the ball!\n", i);
        return 1;
      }
      if( g2==ballGeom && g1==geoms[i] ){
        dWebotsConsolePrintf("Part %d collided with the ball!\n", i);
        return 1;
      }


    }

    /* 
     * If both are, we return 1 without doing nothing to avoid this
     * collision.
     */
    if (g1_robot_part == 1 && g2_robot_part == 1) {
//      dWebotsConsolePrintf("Collided with self!\n");
      return 1;
    }
  }



  return 0;
}

void webots_physics_cleanup() {
  /*
   * Here you need to free any memory you allocated in above, close files, etc.
   * You do not need to free any ODE object, they will be freed by Webots.
   */
}

