qt_add_library(vast-jobs STATIC
    JobExecutor.hpp
    JobExecutor.cpp
)

target_link_libraries(vast-jobs PUBLIC Qt::Core)
