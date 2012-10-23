#include <cv.h>
#include <ml.h>
#include "csv.h"
#include <iostream>

CvMat* trainData;
CvMat* trainClasses;
int train_sample_count;
int nparameters;

void boost_learning();
void svm_learning();
void ddtree_learning();
void bayes_learning();
void knn_learning();
void randomtree_learning();

int main(int argc, char *argv[]) {

  if( argc < 3 ){
    printf("You gave %d arguments.  Please give ./train [filename] [lines in file]\n", argc);
    return 1;
  }

  char* filename = argv[1];
  train_sample_count = atoi(argv[2]);
  nparameters = 11;

  trainData = cvCreateMat( train_sample_count, nparameters, CV_32FC1 ); //32 bit float
  trainClasses = cvCreateMat( train_sample_count, 1, CV_32FC1 );
  cout << "Populating the training matrix...";
  populateTrainingMatrix(trainData, trainClasses, filename);
  
  /**
   * Boosting
   */
  //boost_learning();

  /**
   * SVM
   */
  //svm_learning();

  /**
   * Decision Trees
   */
  ddtree_learning();

  // Bayes
  bayes_learning();

  //KNN
  //knn_learning();

  // Random trees
  randomtree_learning();


  /*
   * Mem management
   */
  cvReleaseMat(&trainData);
  cvReleaseMat(&trainClasses);

  return EXIT_SUCCESS;
}


void boost_learning(){

  // Boost parameters
  CvBoostParams params;
  params.boost_type = CvBoost::REAL;
  params.weak_count = 8;
  params.split_criteria = CvBoost::DEFAULT;
  params.weight_trim_rate = 0; 
  // Run the training
  CvBoost *boost = new CvBoost;
  cout << "Running the Boost training...";
  boost->train(trainData, CV_ROW_SAMPLE, trainClasses, 0, 0, 0, 0, params, false);

  // Save the model
  cout << "Done Training\n";
  cout << "Saving...\n";
  boost->save("./boostmodel.xml");
  cout << "Done!\n";

  /**
   * Test the Boost model
   */
  // http://read.pudn.com/downloads133/ebook/565827/LearningOpenCV_Code/ch13_ex13_3.cpp__.htm
  double fail;
  for( int i = 0; i < train_sample_count; i++ ) {
    double p,r;
    CvMat sample;
    cvGetRow( trainData, &sample, i );
    r = cvmGet(trainClasses,i,0);
    p = boost->predict( &sample );
    //fail = fabs((double)r - responses->data.fl[i]) = FLT_EPSILON ? 1 : 0;
    fail += fabs( p-r );
    //cout << r << "<-Real/Predicted->" << p << "\n";
  }
  cout << "Boost Success rate: " << 1-fail/train_sample_count << "\n";

  // Delete the boost instance
  delete boost;
  
}

void svm_learning(){

  // SVM parameters
  CvSVMParams params;
  params.svm_type = CvSVM::C_SVC;
  params.kernel_type = CvSVM::RBF;

  // Run the training
  CvSVM *svm = new CvSVM;
  cout << "Running the SVM training...";
  fflush( stdout );
  svm->train_auto(trainData, trainClasses, 0, 0, params, 2);

  // Save the model
  cout << "Done Training\n";
  cout << "Saving...\n";
  svm->save("./svmmodel.xml");
  cout << "Done!\n";

  /**
   * Test the Boost model
   */
  // http://read.pudn.com/downloads133/ebook/565827/LearningOpenCV_Code/ch13_ex13_3.cpp__.htm
  double fail;
  for( int i = 0; i < train_sample_count; i++ ) {
    double p,r;
    CvMat sample;
    cvGetRow( trainData, &sample, i );
    r = cvmGet(trainClasses,i,0);
    p = svm->predict( &sample );
    //fail = fabs((double)r - responses->data.fl[i]) = FLT_EPSILON ? 1 : 0;
    fail += fabs( p-r );
    //cout << r << "<-Real/Predicted->" << p << "\n";
  }
  cout << "SVM Success rate: " << 1-fail/train_sample_count << "\n";

  // Delete the boost instance
  delete svm;
  
}

void ddtree_learning(){

  // Boost parameters
  CvDTreeParams params;
/*
  params.boost_type = CvBoost::REAL;
  params.weak_count = 4;
  params.split_criteria = CvBoost::DEFAULT;
  params.weight_trim_rate = 0;
*/
  // Run the training
  CvDTree *ddtree = new CvDTree;
  cout << "Running the DDtree training...";
  fflush( stdout );
//  ddtree->train( trainData, CV_ROW_SAMPLE, trainClasses, 0, 0, 0, 0, params );
  ddtree->train( trainData, CV_ROW_SAMPLE, trainClasses );


  // Save the model
  cout << "Done Training\n";
  cout << "Saving...\n";
  ddtree->save("./ddtreemodel.xml");
  cout << "Done!\n";

  /**
   * Test the Boost model
   */
  // http://read.pudn.com/downloads133/ebook/565827/LearningOpenCV_Code/ch13_ex13_3.cpp__.htm
  double fail;
  for( int i = 0; i < train_sample_count; i++ ) {
    double p,r;
    CvMat sample;
    cvGetRow( trainData, &sample, i );
    r = cvmGet(trainClasses,i,0);
    p = ddtree->predict( &sample )->value;
    //fail = fabs((double)r - responses->data.fl[i]) = FLT_EPSILON ? 1 : 0;
    fail += fabs( p-r );
/*
    if( r!=0 )
      cout << r << "<-Real/Predicted->" << p << "\n";
*/
    
  }
  cout << "Decision Tree Success rate: " << 1-fail/train_sample_count << "\n";

  // Delete the boost instance
  delete ddtree;
  
}

void bayes_learning(){

  // Run the training
  CvNormalBayesClassifier *bayes = new CvNormalBayesClassifier;
  cout << "Running the Bayesian training...";
  fflush( stdout );
  bayes->train( trainData, trainClasses );


  // Save the model
  cout << "Done Training\n";
  cout << "Saving...\n";
  bayes->save("./bayesmodel.xml");
  cout << "Done!\n";

  /**
   * Test the Boost model
   */
  // http://read.pudn.com/downloads133/ebook/565827/LearningOpenCV_Code/ch13_ex13_3.cpp__.htm
  double fail;
  for( int i = 0; i < train_sample_count; i++ ) {
    double p,r;
    CvMat sample;
    cvGetRow( trainData, &sample, i );
    r = cvmGet(trainClasses,i,0);
    p = bayes->predict( &sample );
    //fail = fabs((double)r - responses->data.fl[i]) = FLT_EPSILON ? 1 : 0;
    fail += fabs( p-r );
/*
    if( r!=0 )
      cout << r << "<-Real/Predicted->" << p << "\n";
*/
    
  }
  cout << "Bayes Success rate: " << 1-fail/train_sample_count << "\n";

  // Delete the boost instance
  delete bayes;
  
}

void knn_learning(){

  // Run the training
  CvKNearest *knn = new CvKNearest;
  cout << "Running the KNN training...";
  fflush( stdout );
  knn->train( trainData, trainClasses );


  // Save the model
  cout << "Done Training\n";
  cout << "Saving...\n";
  knn->save("./ddtreemodel.xml");
  cout << "Done!\n";

  /**
   * Test the Boost model
   */
  // http://read.pudn.com/downloads133/ebook/565827/LearningOpenCV_Code/ch13_ex13_3.cpp__.htm
/*
  double fail;
  for( int i = 0; i < train_sample_count; i++ ) {
    double p,r;
    CvMat sample;
    cvGetRow( trainData, &sample, i );
    r = cvmGet(trainClasses,i,0);
    p = knn->predict( &sample )->value;
    //fail = fabs((double)r - responses->data.fl[i]) = FLT_EPSILON ? 1 : 0;
    fail += fabs( p-r );
    if( r!=0 )
      cout << r << "<-Real/Predicted->" << p << "\n";
    
  }
  cout << "KNN Success rate: " << 1-fail/train_sample_count << "\n";
*/
  // Delete the boost instance
  delete knn;
  
}



void randomtree_learning(){

  // Run the training
  CvRTrees *rtree = new CvRTrees;
  cout << "Running the Rtree training...";
  fflush( stdout );
//  ddtree->train( trainData, CV_ROW_SAMPLE, trainClasses, 0, 0, 0, 0, params );
  rtree->train( trainData, CV_ROW_SAMPLE, trainClasses );


  // Save the model
  cout << "Done Training\n";
  cout << "Saving...\n";
  rtree->save("./rtreemodel.xml");
  cout << "Done!\n";

  /**
   * Test the Boost model
   */
  // http://read.pudn.com/downloads133/ebook/565827/LearningOpenCV_Code/ch13_ex13_3.cpp__.htm
  double fail;
  for( int i = 0; i < train_sample_count; i++ ) {
    double p,r;
    CvMat sample;
    cvGetRow( trainData, &sample, i );
    r = cvmGet(trainClasses,i,0);
    p = rtree->predict( &sample );
    //fail = fabs((double)r - responses->data.fl[i]) = FLT_EPSILON ? 1 : 0;
    fail += fabs( p-r );
/*
    if( r!=0 )
      cout << r << "<-Real/Predicted->" << p << "\n";
*/
    
  }
  cout << "Random Tree Success rate: " << 1-fail/train_sample_count << "\n";

  // Delete the boost instance
  delete rtree;
  
}

