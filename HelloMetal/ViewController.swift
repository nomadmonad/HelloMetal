import UIKit
import MetalKit
import QuartzCore

class ViewController: UIViewController {
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil

    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    var objectToDraw: Cube! = nil

    var projectionMatrix: Matrix4!

    var lastFrameTimestamp: CFTimeInterval = 0.0

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
        
        objectToDraw = Cube(device: device)
        
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        try! self.pipelineState = self.device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        
        commandQueue = device.newCommandQueue()

        timer = CADisplayLink(target: self, selector: Selector("newFrame:"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func render() {
        let drawable: CAMetalDrawable? = metalLayer.nextDrawable()
        
        let worldModelMatrix = Matrix4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -7.0)
        objectToDraw.render(commandQueue, pipelineState: pipelineState, drawable: drawable!, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
    }
    
    func gameloop(timeSinceLastUpdate: CFTimeInterval) {
        objectToDraw.updateWithDelta(timeSinceLastUpdate)
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

