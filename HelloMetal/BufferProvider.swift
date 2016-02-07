import Foundation
import Metal

class BufferProvider: NSObject {
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var availableBufferIndex: Int = 0
        var availableResourcesSemaphore: dispatch_semaphore_t

    init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        availableResourcesSemaphore = dispatch_semaphore_create(inflightBuffersCount)
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()

        for i in 0...(inflightBuffersCount - 1) {
            let uniformsBuffer = device.newBufferWithLength(sizeOfUniformsBuffer, options: .CPUCacheModeDefaultCache)
            uniformsBuffers.append(uniformsBuffer)
        }
    }

    deinit {
        for i in 0...self.inflightBuffersCount {
            dispatch_semaphore_signal(self.availableResourcesSemaphore)
        }
    }
    func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
        let buffer = uniformsBuffers[availableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), sizeof(Float) * Matrix4.numberOfElements())
        memcpy(bufferPointer + sizeof(Float) * Matrix4.numberOfElements(), projectionMatrix.raw(), sizeof(Float) * Matrix4.numberOfElements())
        
        availableBufferIndex++
        if availableBufferIndex == inflightBuffersCount {
            availableBufferIndex = 0
        }
        return buffer
    }
}
