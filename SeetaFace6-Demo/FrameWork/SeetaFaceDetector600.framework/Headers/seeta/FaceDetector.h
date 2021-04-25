//
// Created by kier on 19-4-24.
//

#ifndef INC_SEETA_FACEDETECTOR_H
#define INC_SEETA_FACEDETECTOR_H

#include "Common/Struct.h"
#include "CFaceInfo.h"
#include "SeetaFaceDetectorConfig.h"

#include "CFaceDetector.h"
#include <memory>

namespace seeta {
    namespace v6 {
        class FaceDetector {
        public:
            using self = FaceDetector;

            FaceDetector(std::nullptr_t) {}
            ~FaceDetector() = default;

            FaceDetector(const FaceDetector &) = default;
            FaceDetector &operator=(const FaceDetector&) = default;

            enum Property : int32_t {
                PROPERTY_MIN_FACE_SIZE = SEETA_PROPERTY_MIN_FACE_SIZE,
                PROPERTY_THRESHOLD = SEETA_PROPERTY_THRESHOLD,
                PROPERTY_MAX_IMAGE_WIDTH = SEETA_PROPERTY_MAX_IMAGE_WIDTH,
                PROPERTY_MAX_IMAGE_HEIGHT = SEETA_PROPERTY_MAX_IMAGE_HEIGHT,
                PROPERTY_NUMBER_THREADS = SEETA_PROPERTY_NUMBER_THREADS,
                PROPERTY_ARM_CPU_MODE = SEETA_PROPERTY_ARM_CPU_MODE,
            };

            explicit FaceDetector(const SeetaModelSetting &setting) {
                auto object = seeta_v6_FaceDetector_new(&setting);
                if (object == nullptr) throw std::runtime_error(seeta_v6_FaceDetector_error());
                m_impl.reset(object, seeta_v6_FaceDetector_delete);
            }


            explicit FaceDetector(const self *other) {
                if (other == nullptr) throw std::runtime_error("Param 1 is unexpected nullptr.");
                auto object = seeta_v6_FaceDetector_clone(other->m_impl.get());
                if (object == nullptr) throw std::runtime_error(seeta_v6_FaceDetector_error());
                m_impl.reset(object, seeta_v6_FaceDetector_delete);
            }

            self clone() const {
                FaceDetector dolly = nullptr;
                auto object = seeta_v6_FaceDetector_clone(m_impl.get());
                if (object == nullptr) throw std::runtime_error(seeta_v6_FaceDetector_error());
                dolly.m_impl.reset(object, seeta_v6_FaceDetector_delete);
                return dolly;
            }

            SeetaFaceInfoArray detect(const SeetaImageData &image) const {
                return seeta_v6_FaceDetector_detect(m_impl.get(), &image);
            }
            std::vector<SeetaFaceInfo> detect_v2(const SeetaImageData &image) const {
                auto faces = seeta_v6_FaceDetector_detect(m_impl.get(), &image);
                return std::vector<SeetaFaceInfo>(faces.data, faces.data + faces.size);
            }

            void set(Property property, double value) {
                seeta_v6_FaceDetector_set(m_impl.get(), seeta_v6_FaceDetector_Property(property), value);
            }

            double get(Property property) const {
                return seeta_v6_FaceDetector_get(m_impl.get(), seeta_v6_FaceDetector_Property(property));
            }

        private:
            std::shared_ptr<SeetaFaceDetector> m_impl;
        };
    }
    using namespace v6;
}

#endif //INC_SEETA_FACEDETECTOR_H
