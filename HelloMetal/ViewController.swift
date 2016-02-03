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
        objectToDraw.positionX = 0.0
        objectToDraw.positionY = 0.0
        objectToDraw.positionZ = -2.0
        objectToDraw.rotationZ = Matrix4.degreesToRad(45)
        objectToDraw.scale = 0.5
        
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        try! self.pipelineState = self.device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        
        commandQueue = device.newCommandQueue()

        timer = CADisplayLink(target: self, selector: Selector("gameloop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func render() {
        let drawable: CAMetalDrawable? = metalLayer.nextDrawable()
        
        objectToDraw.render(commandQueue, pipelineState: pipelineState, drawable: drawable!, projectionMatrix: projectionMatrix, clearColor: nil)
    }
    
    func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
}

