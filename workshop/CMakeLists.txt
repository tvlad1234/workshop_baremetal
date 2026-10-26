add_executable(workshop)

# Common sources
target_sources(workshop PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common/common_data.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/platform/${PLATFORM}/main.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/platform/${PLATFORM}/parameters.c
)

# Example 1
if(CONFIG_WORKSHOP_EXAMPLE_1)
    target_sources(workshop PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/example_1/example_1.c
    )
    target_include_directories(workshop PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/example_1
    )
endif()

# Example 2
if(CONFIG_WORKSHOP_EXAMPLE_2)
    target_sources(workshop PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/example_2/example_2.c
    )
    target_include_directories(workshop PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/example_2
    )
endif()

# Example 3
if(CONFIG_WORKSHOP_EXAMPLE_3)
    target_sources(workshop PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/example_3/example_3.c
    )
    target_include_directories(workshop PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/example_3
    )
endif()

# IIO example
if(CONFIG_WORKSHOP_IIO_EXAMPLE)
    target_sources(workshop PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/iio_example/iio_example.c
    )
    target_include_directories(workshop PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src/examples/iio_example
    )
endif()

target_include_directories(workshop PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common
    ${CMAKE_CURRENT_SOURCE_DIR}/src/platform/${PLATFORM}
    ${CMAKE_CURRENT_SOURCE_DIR}/src/platform
)

target_compile_definitions(workshop PRIVATE -DADXL355_DEV)

target_link_libraries(workshop no-os)

config_platform_sdk(workshop)
add_flash_target(workshop)
post_build_config(workshop)
