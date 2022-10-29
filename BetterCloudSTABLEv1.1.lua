-- Inputs

dataref("camera_x", "sim/graphics/view/view_x", "readonly")
dataref("camera_y", "sim/graphics/view/view_y", "readonly")
dataref("camera_z", "sim/graphics/view/view_z", "readonly")

dataref("camera_pitch", "sim/graphics/view/view_pitch", "readonly")
dataref("camera_heading", "sim/graphics/view/view_heading", "readonly")

dataref("sun_pitch", "sim/graphics/scenery/sun_pitch_degrees", "readonly")
dataref("sun_heading", "sim/graphics/scenery/sun_heading_degrees", "readonly")

-- Tonemapper

dataref("shutter_speed", "sim/private/controls/photometric/speed", "writable")

dataref("exposure_increase_speed", "sim/private/controls/tone_map/speed_up", "writable")
dataref("exposure_decrease_speed", "sim/private/controls/tone_map/speed_down", "writable")

dataref("white_point", "sim/private/controls/tonemap/clip", "writable")

-- Atmosphere

dataref("ozone_coefficient_red", "sim/private/controls/atmo/ozone_r", "writable")
dataref("ozone_coefficient_green", "sim/private/controls/atmo/ozone_g", "writable")
dataref("ozone_coefficient_blue", "sim/private/controls/atmo/ozone_b", "writable")

dataref("multiple_scattering", "sim/private/controls/scattering/multi_rat", "writable")

-- Clouds

dataref("cloud_density", "sim/private/controls/new_clouds/density", "writable")

dataref("hf_noise_ratio", "sim/private/controls/new_clouds/high_freq_amp", "writable")

dataref("lf_noise_frequency", "sim/private/controls/new_clouds/low_freq_rat", "writable")
dataref("hf_noise_frequency", "sim/private/controls/new_clouds/high_freq_rat", "writable")

dataref("cloud_direct_gain", "sim/private/controls/new_clouds/direct", "writable")

dataref("cloud_phase_forward", "sim/private/controls/new_clouds/phase_fwd", "writable")
dataref("cloud_phase_backward", "sim/private/controls/new_clouds/phase_rev", "writable")

-- XPLM API Access using FFI, do NOT touch

ffi = require("ffi")

if ffi.os == "Windows" then
	xplm = ffi.load("XPLM_64")
else
	xplm = ffi.load("XPLM")
end

ffi.cdef("void XPLMLocalToWorld(double, double, double, double*, double*, double*);")

camera_latitude_pointer = ffi.new("double[1]", {0.0})
camera_longitude_pointer = ffi.new("double[1]", {0.0})
camera_altitude_pointer = ffi.new("double[1]", {0.0})

function get_camera_parameters()
	xplm.XPLMLocalToWorld(ffi.new("double", camera_x), ffi.new("double", camera_y), ffi.new("double", camera_z), camera_latitude_pointer, camera_longitude_pointer, camera_altitude_pointer)

	return camera_latitude_pointer[0], camera_longitude_pointer[0], camera_altitude_pointer[0]
end

-- Functions

function clamp(input_value, output_start, output_end)
	if input_value < output_start then
		return output_start
	elseif input_value > output_end then
		return output_end
	else
		return input_value
	end
end

function map(input_value, input_start, input_end, output_start, output_end)
	slope = (output_end - output_start) / (input_end - input_start)

	return clamp(output_start + (slope * (input_value - input_start)), math.min(output_start, output_end), math.max(output_start, output_end))
end

function update_simulator()
	white_point = map(sun_pitch, -5.0, -10.0, 50.0, 10.0)

	multiple_scattering = map(sun_pitch, 20.0, 10.0, 2.5, 5.0)

	cloud_direct_gain = map(sun_pitch, -3.0, 5.0, 3.25, 1.75)
end

shutter_speed = 125.0

exposure_increase_speed = 10.0
exposure_decrease_speed = 10.0

do_every_frame("update_simulator()")
