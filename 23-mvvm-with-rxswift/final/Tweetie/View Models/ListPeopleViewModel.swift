/*
 * Copyright (c) 2016-2017 Razeware LLC
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

import Foundation
import Accounts
import Unbox

import RealmSwift
import RxSwift
import RxRealm
import RxCocoa

class ListPeopleViewModel {

  private let bag = DisposeBag()

  let list: ListIdentifier
  let apiType: TwitterAPIProtocol.Type

  // MARK: - Input
  let account: Driver<TwitterAccount.AccountStatus>

  // MARK: - Output
  let people = Variable<[User]?>(nil)

  // MARK: - Init
  init(account: Driver<TwitterAccount.AccountStatus>,
       list: ListIdentifier,
       apiType: TwitterAPIProtocol.Type = TwitterAPI.self) {

    self.account = account
    self.list = list
    self.apiType = apiType

    bindOutput()
  }

  func bindOutput() {
    //observe the current account status
    let currentAccount = account
      .filter { account in
        switch account {
        case .authorized: return true
        default: return false
        }
      }
      .map { account -> ACAccount in
        switch account {
        case .authorized(let acaccount):
          return acaccount
        default: fatalError()
        }
      }
      .distinctUntilChanged()

    //fetch list members
    currentAccount.asObservable()
      .flatMapLatest(apiType.members(of: list))
      .map { users in
        return (try? unbox(dictionaries: users, allowInvalidElements: true) as [User]) ?? []
      }
      .bindTo(people)
      .addDisposableTo(bag)
  }
}
