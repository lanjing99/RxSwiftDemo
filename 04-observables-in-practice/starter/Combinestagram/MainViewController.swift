/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    private let bag = DisposeBag()
    private let images = Variable<[UIImage]>([])

  override func viewDidLoad() {
    super.viewDidLoad()
    images.asObservable().subscribe(onNext: { [weak self] photos in
        guard let imagePreview = self?.imagePreview else{
            return
        }
        imagePreview.image = UIImage.collage(images: photos, size: imagePreview.frame.size)
    })
    .addDisposableTo(bag)
    
    images.asObservable().subscribe(onNext: { [weak self] photos in
        self?.updateUI(photos: photos)
    })
    .addDisposableTo(bag)
  }

    
    
    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
    
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  @IBAction func actionClear() {
    images.value = []

  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else {
        return
    }
    PhotoWriter.save(image).subscribe( onError: {[weak self] error in
        self?.showMessage("error", description: error.localizedDescription)
    }, onCompleted: {[weak self] error in
        self?.showMessage("saved")
        self?.actionClear()
    })
    .addDisposableTo(bag)
  }

  @IBAction func actionAdd() {
    let photosViewController = storyboard!.instantiateViewController(
        withIdentifier: "PhotosViewController") as! PhotosViewController
    navigationController!.pushViewController(photosViewController, animated:
        true)
    photosViewController.selectedPhotos.subscribe(onNext: {[weak self] newImage in
        guard let images = self?.images else{
            return
        }
        images.value.append(newImage)
        }, onDisposed: {
            print("completed photo selection")
    }   )
        .addDisposableTo(bag)
  }

  func showMessage(_ title: String, description: String? = nil) {
    alert(title: title, text: description).subscribe(onNext: {
        self.dismiss(animated: true, completion: nil)
    })
    .addDisposableTo(bag)
  }
}
