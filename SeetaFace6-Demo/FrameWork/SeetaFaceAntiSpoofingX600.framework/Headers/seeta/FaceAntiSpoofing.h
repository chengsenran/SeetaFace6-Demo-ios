#ifndef _FACEANTISPOOFING_H_
#define _FACEANTISPOOFING_H_

#include "Common/Struct.h"

#include <string>
#include <vector>


namespace seeta
{
    namespace v6
    {

        class FaceAntiSpoofing {
        public:
            /*
             * ����ʶ��״̬
             */
            enum Status
            {
                REAL = 0,   ///< ��ʵ����
                SPOOF = 1,  ///< ������������������
                FUZZY = 2,  ///< �޷��жϣ����������������ã�
                DETECTING = 3,  ///< ���ڼ��
            };

            enum Property {
                PROPERTY_NUMBER_THREADS = 4,
                PROPERTY_ARM_CPU_MODE = 5
            };


            /**
             * \brief ����ģ���ļ�
             * \param setting ģ���ļ�, 0-�ֲ��������ļ�����ѡ����1-ȫ�ֻ������ļ�����ѡ��
             */
            SEETA_API explicit FaceAntiSpoofing( const seeta::ModelSetting &setting );
            SEETA_API ~FaceAntiSpoofing();


            /**
             * \brief ������
             * \param [in] image ����ͼ����Ҫ RGB ��ɫͨ��
             * \param [in] face Ҫʶ�������λ��
             * \param [in] points Ҫʶ�������������
             * \return ����״̬ @see Status
             * \note �˺�����֧�ֶ��̵߳��ã��ڶ��̻߳�������Ҫ������Ӧ�� FaceAntiSpoofing �Ķ���ֱ���ü�⺯��
             * \note ��ǰ�汾���ܷ��� REAL, SPOOF, FUZZY
             * \see SeetaImageData, SeetaRect, PointF, Status
             */
            SEETA_API Status Predict( const SeetaImageData &image, const SeetaRect &face, const SeetaPointF *points ) const;

            /**
            * \brief �����壨Videoģʽ��
            * \param [in] image ����ͼ����Ҫ RGB ��ɫͨ��
            * \param [in] face Ҫʶ�������λ��
            * \param [in] points Ҫʶ�������������
            * \return ����״̬ @see Status
            * \note �˺�����֧�ֶ��̵߳��ã��ڶ��̻߳�������Ҫ������Ӧ�� FaceAntiSpoofing �Ķ���ֱ���ü�⺯��
            * \note ��Ҫ��������֡���У�����Ҫ������һ����Ƶ�ǣ���Ҫ���� ResetVideo ���ü��״̬
            * \note ��ǰ�汾���ܷ��� REAL, SPOOF, DETECTION
            * \see SeetaImageData, SeetaRect, PointF, Status
            */
            SEETA_API Status PredictVideo( const SeetaImageData &image, const SeetaRect &face, const SeetaPointF *points ) const;

            /**
             * \brief ���� Video����ʼ��һ�� PredictVideo ʶ��
             */
            SEETA_API void ResetVideo();

            /**
             * \brief ��ȡ�������ڲ�����
             * \param [out] clarity ���������������
             * \param [out] reality ��ʵ��
             * \note ��ȡ������һ�ε��� Predict �� PredictVideo �ӿں��ڲ�����ֵ
             */
            SEETA_API void GetPreFrameScore( float *clarity = nullptr, float *reality = nullptr );

            /**
             * ���� Video ģʽ�У�ʶ����Ƶ֡����������֡��Ϊ��ֵ�Ժ�Ż��з���ֵ
             * \param [in] number ��Ƶ֡��
             */
            SEETA_API void SetVideoFrameCount( int32_t number );

            /**
             * \return ��ȡ��Ƶ֡������
             */
            SEETA_API int32_t GetVideoFrameCount() const;

            /**
             * ������ֵ
             * \param [in] clarity ��������ֵ
             * \param [in] reality ������ֵ
             * \note clarity Խ��Ҫ�������ͼ������Խ�ߣ�reality Խ�߶�ʶ��Ҫ��Խ�ϸ�
             * \note Ĭ����ֵΪ 0.3, 0.8
             */
            SEETA_API void SetThreshold( float clarity, float reality );
			
			 /**
             * ����ȫ����ֵ
             * \param [in] box_thresh ȫ�ּ����ֵ
             * \note Ĭ����ֵΪ 0.8
             */
			 SEETA_API void SetBoxThresh(float box_thresh);
			 
			 SEETA_API float GetBoxThresh()const;

            /**
             * ��ȡ��ֵ
             * \param [out] clarity ��������ֵ
             * \param [out] reality ������ֵ
             */
            SEETA_API void GetThreshold( float *clarity = nullptr, float *reality = nullptr ) const;

            SEETA_API void set(Property property, double value);

            SEETA_API double get(Property property) const;
        private:
            FaceAntiSpoofing( const FaceAntiSpoofing & ) = delete;
            const FaceAntiSpoofing &operator=( const FaceAntiSpoofing & ) = delete;

        private:
            class Implement;
            Implement *m_impl;
        };
    }
    using namespace v6;
}

#endif
