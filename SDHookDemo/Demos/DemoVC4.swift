//
//  DemoVC4.swift
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/12/26.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

import Foundation

class DemoVC4: BaseViewController {
    var hookID: String?
    var rootVC: UIViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        let imp: @convention(block) (UIViewController, Bool) -> Void = { (vc, flag) in
            vc.callOriginalMethod {
                vc.viewDidDisappear(flag)
            }
            print(vc)
        }
        rootVC = navigationController?.children.first
        hookID = rootVC?.hookMethod(#selector(UIViewController.viewDidDisappear(_:)), impBlock: imp)
    }

    deinit {
        // 因为是hook的一个常驻的实例，所以需要在deinit时移除hook操作
        if let id = hookID {
            rootVC?.removeHook(#selector(UIViewController.viewDidDisappear(_:)), strId: id)
        }
    }
}
