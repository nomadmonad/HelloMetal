import UIKit
import MetalKit
import QuartzCore

protocol MetalViewControllerDelegate : class{
    func updateLogic(timeSinceLastUpdate:CFTimeInterval)
    func renderObjects(drawable:CAMetalDrawable)
}

class MetalViewController: UIViewController {
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    var projectionMatrix: Matrix4!
    var lastFrameTimestamp: CFTimeInterval = 0.0
    
    weak var metalViewControllerDelegate: MetalViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let aspect = Float(self.view.bounds.size.width / self.view.bounds.size.height)
        projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: aspect, nearZ: 0.01, farZ: 100.0)
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)

        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.Add;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.Add;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.One;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.One;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.OneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.OneMinusSourceAlpha;

        try! self.pipelineState = self.device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)

        commandQueue = device.newCommandQueue()

        timer = CADisplayLink(target: self, selector: Selector("newFrame:"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)        
    }

    func render() {
        if let drawable = metalLayer.nextDrawable() {
            self.metalViewControllerDelegate?.renderObjects(drawable)
        }
    }

    func gameloop(timeSinceLastUpdate: CFTimeInterval) {
        self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate)
        autoreleasepool {
            self.render()
        }
    }

    func newFrame(displayLink: CADisplayLink) {
        if lastFrameTimestamp == 0.0 {
            lastFrameTimestamp = displayLink.timestamp
        }

        let elapsed: CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
        lastFrameTimestamp = displayLink.timestamp

        gameloop(elapsed)
    }
}

