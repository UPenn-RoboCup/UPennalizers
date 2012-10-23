#include "csv.h"

class CVSRow
{
    public:
        std::string const& operator[](std::size_t index) const
        {
            return m_data[index];
        }
        std::size_t size() const
        {
            return m_data.size();
        }
        void readNextRow(std::istream& str)
        {
            std::string         line;
            std::getline(str,line);

            std::stringstream   lineStream(line);
            std::string         cell;

            m_data.clear();
            while(std::getline(lineStream,cell,' '))
            {
                m_data.push_back(cell);
            }
        }
    private:
        std::vector<std::string>    m_data;
};

std::istream& operator>>(std::istream& str,CVSRow& data)
{
    data.readNextRow(str);
    return str;
}

void populateTrainingMatrix(CvMat* trainData, CvMat* trainClasses, const char* filename){

    std::ifstream       file( filename );
    CVSRow              row;
    int i = 0;
    while(file >> row)
    {
        cvmSet(trainClasses,i,0, atof(row[0].c_str()) );
        for( int j=0; j < trainData->cols; j++ ){
            double tmp = atof(row[j+1].substr(2).c_str());
            cvmSet(trainData,i,j,tmp);
        }
        //std::cout << "Class(" << cvmGet(trainClasses,i,0) << ")" << cvmGet(trainData,i,0) << "\n";
        i++;
    }
}

/*
int main() {
    populateTrainingMatrix();
}
*/

