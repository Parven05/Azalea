package azalea

import "base:runtime"
import "core:fmt"
import "core:time"
import "vendor:wgpu"

REQUEST_TIMEOUT_MS :: 5000

Adapter_Request :: struct {
	adapter:       wgpu.Adapter,
	request_ended: bool,
}

Device_Request :: struct {
	device:        wgpu.Device,
	request_ended: bool,
}

request_adapter_sync :: proc(
	instance: wgpu.Instance,
	options: ^wgpu.RequestAdapterOptions = nil,
) -> wgpu.Adapter {
	ud: Adapter_Request

	on_adapter :: proc "c" (
		status: wgpu.RequestAdapterStatus,
		adapter: wgpu.Adapter,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		context = runtime.default_context()
		ud := cast(^Adapter_Request)userdata1
		if status == .Success {
			ud.adapter = adapter
		} else {
			fmt.eprintln("could not get webgpu adapter:", message)
		}
		ud.request_ended = true
	}

	wgpu.InstanceRequestAdapter(
		instance,
		options,
		{mode = .AllowProcessEvents, callback = on_adapter, userdata1 = &ud, userdata2 = nil},
	)

	waited_ms := 0
	for !ud.request_ended {
		if waited_ms >= REQUEST_TIMEOUT_MS {
			fmt.eprintln("timed out waiting for adapter")
			return nil
		}
		wgpu.InstanceProcessEvents(instance)
		time.sleep(1 * time.Millisecond)
		waited_ms += 1
	}

	return ud.adapter
}

request_device_sync :: proc(
	instance: wgpu.Instance,
	adapter: wgpu.Adapter,
	descriptor: ^wgpu.DeviceDescriptor,
) -> wgpu.Device {
	ud: Device_Request

	on_device :: proc "c" (
		status: wgpu.RequestDeviceStatus,
		device: wgpu.Device,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		context = runtime.default_context()
		ud := cast(^Device_Request)userdata1
		if status == .Success {
			ud.device = device
		} else {
			fmt.eprintln("could not get webgpu device:", message)
		}
		ud.request_ended = true
	}

	wgpu.AdapterRequestDevice(
		adapter,
		descriptor,
		{mode = .AllowProcessEvents, callback = on_device, userdata1 = &ud, userdata2 = nil},
	)

	waited_ms := 0
	for !ud.request_ended {
		if waited_ms >= REQUEST_TIMEOUT_MS {
			fmt.eprintln("timed out waiting for device")
			return nil
		}
		wgpu.InstanceProcessEvents(instance)
		time.sleep(1 * time.Millisecond)
		waited_ms += 1
	}

	return ud.device
}

inspect_adapter :: proc(adapter: wgpu.Adapter) {
	limits, limit_status := wgpu.AdapterGetLimits(adapter)
	if limit_status == .Success {
		fmt.println("adapter limits")
		fmt.println(" - maxTextureDimension1D:", limits.maxTextureDimension1D)
		fmt.println(" - maxTextureDimension2D:", limits.maxTextureDimension2D)
		fmt.println(" - maxTextureDimension3D:", limits.maxTextureDimension3D)
		fmt.println(" - maxTextureArrayLayers:", limits.maxTextureArrayLayers)
	} else {
		fmt.eprintln("failed to inspect adapter limits")
	}

	features := wgpu.AdapterGetFeatures(adapter)
	defer wgpu.SupportedFeaturesFreeMembers(features)
	fmt.println("adapter features")
	for feature, i in features.features[:features.featureCount] {
		fmt.printfln(" - [%d] %v", i, feature)
	}

	info, info_status := wgpu.AdapterGetInfo(adapter)
	if info_status == .Success {
		fmt.println("adapter info")
		fmt.println(" - vendorID:", info.vendorID)
		fmt.println(" - vendor:", info.vendor)
		fmt.println(" - architecture:", info.architecture)
		fmt.println(" - deviceID:", info.deviceID)
		fmt.println(" - device:", info.device)
		fmt.println(" - description:", info.description)
		fmt.println(" - adapterType:", info.adapterType)
		fmt.println(" - backendType:", info.backendType)
	}
	wgpu.AdapterInfoFreeMembers(info)
}

inspect_device :: proc(device: wgpu.Device) {
	limits, limit_status := wgpu.DeviceGetLimits(device)
	if limit_status == .Success {
		fmt.println("device limits")
		fmt.println(" - maxTextureDimension1D:", limits.maxTextureDimension1D)
		fmt.println(" - maxTextureDimension2D:", limits.maxTextureDimension2D)
		fmt.println(" - maxTextureDimension3D:", limits.maxTextureDimension3D)
		fmt.println(" - maxTextureArrayLayers:", limits.maxTextureArrayLayers)
	} else {
		fmt.eprintln("failed to inspect device limits")
	}

	features := wgpu.DeviceGetFeatures(device)
	defer wgpu.SupportedFeaturesFreeMembers(features)
	fmt.println("device features")
	for feature, i in features.features[:features.featureCount] {
		fmt.printfln(" - [%d] %v", i, feature)
	}
}

on_device_lost :: proc "c" (
	device: ^wgpu.Device,
	reason: wgpu.DeviceLostReason,
	message: string,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	context = runtime.default_context()
	if reason == .Destroyed {
		return
	}

	fmt.eprintfln("device lost: reason=%v message=%s", reason, message)
}

on_uncaptured_error :: proc "c" (
	device: ^wgpu.Device,
	type: wgpu.ErrorType,
	message: string,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	context = runtime.default_context()

	fmt.eprintfln("uncaptured device error: type=%v message=%s", type, message)
}

main :: proc() {
	// instance
	instance_desc: wgpu.InstanceDescriptor
	instance := wgpu.CreateInstance(&instance_desc)
	if instance == nil {
		fmt.eprintln("failed to create wgpu instance")
		return
	}
	defer wgpu.InstanceRelease(instance)
	fmt.println("wgpu instance created:", instance)

	// adapter
	adapter_options: wgpu.RequestAdapterOptions
	adapter_options.powerPreference = .HighPerformance

	adapter := request_adapter_sync(instance, &adapter_options)
	if adapter == nil {
		fmt.eprintln("failed to request adapter")
		return
	}
	defer wgpu.AdapterRelease(adapter)
	fmt.println("adapter has been requested:", adapter)

	inspect_adapter(adapter)

	// device
	device_desc: wgpu.DeviceDescriptor
	device_desc.label = "My Device"
	device_desc.requiredFeatureCount = 0
	device_desc.requiredLimits = nil
	device_desc.defaultQueue.label = "The default queue"
	device_desc.deviceLostCallbackInfo = {
		mode     = .AllowSpontaneos,
		callback = on_device_lost,
	}
	device_desc.uncapturedErrorCallbackInfo = {
		callback = on_uncaptured_error,
	}

	device := request_device_sync(instance, adapter, &device_desc)
	if device == nil {
		fmt.eprintln("failed to request device")
		return
	}
	defer wgpu.DeviceRelease(device)
	fmt.println("device has been requested")

	inspect_device(device)
}
