LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

# ---------------------------------------------------------------------------------
# 				Common definitons
# ---------------------------------------------------------------------------------

libmm-vdec-def := -D__alignx\(x\)=__attribute__\(\(__aligned__\(x\)\)\)
libmm-vdec-def += -D__align=__alignx
libmm-vdec-def += -Dinline=__inline
libmm-vdec-def += -g -O3
libmm-vdec-def += -DIMAGE_APPS_PROC
libmm-vdec-def += -D_ANDROID_
libmm-vdec-def += -DCDECL
libmm-vdec-def += -DT_ARM
libmm-vdec-def += -DNO_ARM_CLZ
libmm-vdec-def += -UENABLE_DEBUG_LOW
libmm-vdec-def += -UENABLE_DEBUG_HIGH
libmm-vdec-def += -DENABLE_DEBUG_ERROR
libmm-vdec-def += -UINPUT_BUFFER_LOG
libmm-vdec-def += -UOUTPUT_BUFFER_LOG
libmm-vdec-def += -Wno-parentheses
libmm-vdec-def += -D_ANDROID_ICS_
libmm-vdec-def += -D_MSM8974_
libmm-vdec-def += -DPROCESS_EXTRADATA_IN_OUTPUT_PORT
libmm-vdec-def += -DMAX_RES_1080P
libmm-vdec-def += -DMAX_RES_1080P_EBI

TARGETS_THAT_USE_HEVC_ADSP_HEAP := msm8226 msm8974
TARGETS_THAT_HAVE_VENUS_HEVC := apq8084 msm8994
TARGETS_THAT_NEED_HEVC_LIB := msm8974 msm8610 msm8226 msm8916
TARGETS_THAT_NEED_SW_HEVC := msm8974 msm8226 msm8916

ifeq ($(call is-board-platform-in-list, $(TARGETS_THAT_USE_HEVC_ADSP_HEAP)),true)
libmm-vdec-def += -D_HEVC_USE_ADSP_HEAP_
endif

ifeq ($(call is-board-platform-in-list, $(TARGETS_THAT_HAVE_VENUS_HEVC)),true)
libmm-vdec-def += -DVENUS_HEVC
endif

ifeq ($(TARGET_BOARD_PLATFORM),msm8610)
libmm-vdec-def += -DSMOOTH_STREAMING_DISABLED
libmm-vdec-def += -DH264_PROFILE_LEVEL_CHECK
endif

ifeq ($(TARGET_USES_ION),true)
libmm-vdec-def += -DUSE_ION
endif

ifneq (1,$(filter 1,$(shell echo "$$(( $(PLATFORM_SDK_VERSION) >= 18 ))" )))
libmm-vdec-def += -DANDROID_JELLYBEAN_MR1=1
endif

ifeq ($(call is-platform-sdk-version-at-least,27),true) # O-MR1
libmm-vdec-def += -D_ANDROID_O_MR1_DIVX_CHANGES
endif

include $(CLEAR_VARS)

# Common Includes
libmm-vdec-inc          := $(LOCAL_PATH)/inc
libmm-vdec-inc          += $(OMX_VIDEO_PATH)/vidc/common/inc
libmm-vdec-inc          += hardware/qcom/media/mm-core/inc
libmm-vdec-inc          += $(TARGET_OUT_HEADERS)/qcom/display
libmm-vdec-inc          += $(TARGET_OUT_HEADERS)/adreno
libmm-vdec-inc          += $(TOP)/frameworks/native/include/media/openmax
libmm-vdec-inc          += $(TOP)/frameworks/native/include/media/hardware
libmm-vdec-inc          += frameworks/native/libs/nativewindow/include/
libmm-vdec-inc          += frameworks/native/libs/arect/include/
libmm-vdec-inc          += frameworks/native/libs/nativebase/include
libmm-vdec-inc      	+= hardware/qcom/media/libc2dcolorconvert
libmm-vdec-inc      	+= $(TOP)/frameworks/av/include/media/stagefright
ifeq ($(call is-platform-sdk-version-at-least,27),true) #O_MR1
libmm-vdec-inc          += $(TOP)/frameworks/native/libs/nativewindow/include
libmm-vdec-inc          += $(TOP)/frameworks/native/libs/arect/include
libmm-vdec-inc          += $(TOP)/frameworks/native/libs/nativebase/include
endif
libmm-vdec-inc      	+= $(TARGET_OUT_HEADERS)/mm-video/SwVdec

ifeq ($(PLATFORM_SDK_VERSION), 18)  #JB_MR2
libmm-vdec-def += -DANDROID_JELLYBEAN_MR2=1
libmm-vdec-inc += hardware/qcom/media/libstagefrighthw
endif

ifeq ($(call is-platform-sdk-version-at-least, 19),true)
# This feature is enabled for Android KK+
libmm-vdec-def += -DADAPTIVE_PLAYBACK_SUPPORTED
endif

ifeq ($(call is-platform-sdk-version-at-least, 22),true)
# This feature is enabled for Android LMR1
libmm-vdec-def += -DFLEXYUV_SUPPORTED
endif

ifeq ($(TARGET_USES_MEDIA_EXTENSIONS),true)
libmm-vdec-def += -DALLOCATE_OUTPUT_NATIVEHANDLE
endif

# ---------------------------------------------------------------------------------
# 			Make the Shared library (libOmxVdec)
# ---------------------------------------------------------------------------------

include $(CLEAR_VARS)

LOCAL_MODULE                    := libOmxVdec
LOCAL_MODULE_TAGS               := optional
LOCAL_VENDOR_MODULE             := true
LOCAL_CFLAGS                    := $(libmm-vdec-def) -Werror -Wno-error
LOCAL_C_INCLUDES                += $(libmm-vdec-inc)

LOCAL_PRELINK_MODULE    := false
LOCAL_SHARED_LIBRARIES  := liblog libutils libui libcutils libdl

LOCAL_HEADER_LIBRARIES += display_headers
LOCAL_SHARED_LIBRARIES  += libqdMetaData

LOCAL_HEADER_LIBRARIES  := media_plugin_headers

LOCAL_HEADER_LIBRARIES  += generated_kernel_headers

LOCAL_SRC_FILES         := src/frameparser.cpp
LOCAL_SRC_FILES         += src/h264_utils.cpp
LOCAL_SRC_FILES         += src/ts_parser.cpp
LOCAL_SRC_FILES         += src/mp4_utils.cpp
LOCAL_SRC_FILES         += src/hevc_utils.cpp
LOCAL_STATIC_LIBRARIES  := libOmxVidcCommon
LOCAL_SRC_FILES         += src/omx_vdec_msm8974.cpp
LOCAL_CFLAGS            += -Wno-error
include $(BUILD_SHARED_LIBRARY)


# ---------------------------------------------------------------------------------
# 			Make the Shared library (libOmxVdecHevc)
# ---------------------------------------------------------------------------------

include $(CLEAR_VARS)

# libOmxVdecHevc library is not built for OSS builds as QCPATH is null in OSS builds.

ifneq "$(wildcard $(QCPATH) )" ""
ifeq ($(call is-board-platform-in-list, $(TARGETS_THAT_NEED_HEVC_LIB)),true)

LOCAL_MODULE                    := libOmxVdecHevc
LOCAL_MODULE_TAGS               := optional
LOCAL_VENDOR_MODULE             := true
LOCAL_CFLAGS                    := $(libmm-vdec-def)
LOCAL_C_INCLUDES                += $(libmm-vdec-inc)

LOCAL_HEADER_LIBRARIES := generated_kernel_headers

LOCAL_PRELINK_MODULE    := false
LOCAL_SHARED_LIBRARIES  := liblog libutils libbinder libcutils libdl

LOCAL_SHARED_LIBRARIES  += libqdMetaData

LOCAL_SRC_FILES         := src/frameparser.cpp
LOCAL_SRC_FILES         += src/h264_utils.cpp
LOCAL_SRC_FILES         += src/ts_parser.cpp
LOCAL_SRC_FILES         += src/mp4_utils.cpp
LOCAL_SRC_FILES         += src/hevc_utils.cpp

LOCAL_STATIC_LIBRARIES  := libOmxVidcCommon

include $(BUILD_SHARED_LIBRARY)

endif
endif

# ---------------------------------------------------------------------------------
#                END
# ---------------------------------------------------------------------------------
