package azalea

import "base:runtime"
import "core:fmt"
import "core:log"
import "vendor:wgpu"


Adapter_Request :: struct {
	adapter:       wgpu.Adapter,
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
			log.error("could not get webgpu adapter:", message)
		}
		ud.request_ended = true
	}

	wgpu.InstanceRequestAdapter(
		instance,
		options,
		{mode = .AllowProcessEvents, callback = on_adapter, userdata1 = &ud, userdata2 = nil},
	)

	for !ud.request_ended {
		wgpu.InstanceProcessEvents(instance)
	}

	return ud.adapter
}

inspect_adapter :: proc(adapter: wgpu.Adapter) {
	limits, limit_status := wgpu.AdapterGetLimits(adapter)
	limits.nextInChain = nil

	if limit_status == .Success {
		fmt.println("adapter limits")
		fmt.println(" - maxTextureDimension1D:", limits.maxTextureDimension1D)
		fmt.println(" - maxTextureDimension2D:", limits.maxTextureDimension2D)
		fmt.println(" - maxTextureDimension3D:", limits.maxTextureDimension3D)
		fmt.println(" - maxTextureArrayLayers:", limits.maxTextureArrayLayers)
	} else {
		log.error("failed to inspect adapter")
	}

	features := wgpu.AdapterGetFeatures(adapter)
	fmt.println("adapter Features")
	for feature, i in features.features[:features.featureCount] {
		fmt.printfln("- [%d] %v", i, feature)
	}

	properties, properties_status := wgpu.AdapterGetInfo(adapter)
	properties.nextInChain = nil
	if properties_status == .Success {
		fmt.println("adapter info")
		fmt.println(" - vendorID:", properties.vendorID)
		fmt.println(" - vendor:", properties.vendor)
		fmt.println(" - architecture:", properties.architecture)
		fmt.println(" - deviceID:", properties.deviceID)
		fmt.println(" - device:", properties.device)
		fmt.println(" - vendorID:", properties.vendorID)
		fmt.println(" - description", properties.description)
		fmt.println(" - adapterType", properties.adapterType)
		fmt.println(" - backendType", properties.backendType)
	}
	wgpu.AdapterInfoFreeMembers(properties)

}

main :: proc() {
	context.logger = log.create_console_logger()

	// instance
	desc: wgpu.InstanceDescriptor = {}
	desc.nextInChain = nil

	instance: wgpu.Instance = wgpu.CreateInstance(&desc)
	if instance == nil {
		log.error("failed to create wgpu instance")
		return
	} else {
		fmt.println("wpgu instance created:", instance)
	}
	defer wgpu.InstanceRelease(instance)

	// adapter
	adapter_options: wgpu.RequestAdapterOptions = {}
	adapter_options.nextInChain = nil
	adapter_options.powerPreference = .HighPerformance
	adapter: wgpu.Adapter = request_adapter_sync(instance, &adapter_options)

	if adapter == nil {
		log.error("failed to request adapter")
		return
	} else {
		fmt.println("adapter has been requested:", adapter)
	}

	inspect_adapter(adapter)

	defer wgpu.AdapterRelease(adapter)

}
