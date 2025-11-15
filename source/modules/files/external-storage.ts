import type Umbreld from '../../index.js'

// External storage is disabled in Docker containers
export default class ExternalStorage {
	#umbreld: Umbreld
	logger: Umbreld['logger']
	formatJobs: Set<string> = new Set()

	constructor(umbreld: Umbreld) {
		this.#umbreld = umbreld
		const {name} = this.constructor
		this.logger = umbreld.logger.createChildLogger(`files:${name.toLocaleLowerCase()}`)
	}

	// Disabled in Docker container
	async supported() {
		return false
	}

	async start() {
		// External storage is disabled in Docker container
		return
	}

	async stop() {
		// External storage is disabled in Docker container
		return
	}

	async unmountExternalDevice(deviceId: string, {remove = true} = {}) {
		this.logger.error(`External storage is not supported in Docker container`)
		return false
	}

	async formatExternalDevice(args: any) {
		this.logger.error(`External storage is not supported in Docker container`)
		throw new Error('External storage is not supported in Docker container')
	}

	async getExternalDevicesWithVirtualMountPoints() {
		return []
	}

	async getMountedExternalDevices() {
		return []
	}

	async isExternalDeviceConnectedOnUnsupportedDevice() {
		return false
	}
}
