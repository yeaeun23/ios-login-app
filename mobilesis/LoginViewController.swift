//
//  LoginViewController.swift
//  mobilesis
//
//  Created by 서울신문사 on 2020/02/20.
//  Copyright © 2020 서울신문사. All rights reserved.
//

import UIKit
import CommonCrypto

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var id: UITextField!
    @IBOutlet var pw: UITextField!
    
    var token, empno, nounce, pwd, sessionid: String!
    var loginResult: Int = 0
    let semaphore = DispatchSemaphore(value: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 키보드 설정
        self.id.delegate = self
        self.id.keyboardType = .numberPad
        
        self.pw.delegate = self
        self.pw.keyboardType = .default
        self.pw.returnKeyType = .go
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onResume), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // id(empno) 기억
        self.id.text = UserDefaults.standard.value(forKey: "empno") as? String
        
        // id, pw 필드 포커스
        if self.id.text!.isEmpty {
            self.id.becomeFirstResponder()
        }
        else {
            self.pw.becomeFirstResponder()
        }
        
        print("--loginView viewDidLoad")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 버전 체크
        checkVersion()
        
        print("--loginView viewDidAppear")
    }
    
    @objc func onResume() {
        // 버전 체크
        checkVersion()
        
        print("--loginView onResume")
    }
    
    // pw 필드에서 엔터 입력
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(self.pw) {
            login()
        }
        
        return true
    }
    
    // 빈 화면 터치 시 키보드 숨기기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
    
    func checkVersion() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        var localVer: String! {
            guard let dictionary = Bundle.main.infoDictionary,
                let version = dictionary["CFBundleShortVersionString"] as? String else { return nil }
            
            return version
        }
        
        var serverVer: String!
        if let url = URL(string: "https://mgate.seoul.co.kr/SISXML/SISXML.aspx?FN=checkVerIOS") {
            do {
                serverVer = try String(contentsOf: url)
            } catch {
                // contents could not be loaded
            }
        } else {
            // the URL was bad!
        }
        
        print("localVer:", localVer as String)
        print("serverVer:", serverVer as String)
        
        if serverVer == "false" || serverVer == "" {
            showAlert(title: "필수 업데이트", msg: "인터넷 연결을 확인하세요.")
        }
        else if (serverVer as NSString).integerValue > (localVer as NSString).integerValue {
            showUpdateAlert()
        }
        else {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func showUpdateAlert() {
        let alertController = UIAlertController(title: "필수 업데이트", message: "앱 최신 버전이 있습니다. 업데이트 하시겠습니까?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "업데이트", style: .default) { _ in
            if let url = URL(string: "itms-services://?action=download-manifest&url=https://mob.seoul.co.kr/app/plist/mobilesis.plist") {
                print("--Update Start")
                UIApplication.shared.open(url, options: [:])
                print("--Update Complete")
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func showAlert(title: String, msg: String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .cancel)
        
        alertController.addAction(okAction)
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func login() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        if self.id.text!.isEmpty {
            loginResult = 1
        }
        else if self.pw.text!.isEmpty {
            loginResult = 2
        }
        else if self.id.text!.count != 7 {
            loginResult = 3
        }
        else {
            // empno 구하기
            empno = self.id.text
            print("empno:", empno!)
            
            // nounce 구하기
            var jsonDict = ["id": empno!]
            nounce = postUrl(jsonDict: jsonDict, str: "getNounce")
            print("nounce:", nounce!)
            
            // pwd 구하기
            pwd = getMD5(getMD5(self.pw.text!)! + nounce)
            print("pwd:", pwd!)
            
            // sessionid 구하기
            jsonDict = ["nounce": nounce, "empno": empno, "pwd": pwd]
            sessionid = postUrl(jsonDict: jsonDict, str: "getAuth")
            
            if sessionid != "-1"
            {
                sessionid = sessionid?.components(separatedBy: "∥")[1];
                print("sessionid:", sessionid!)
                
                // empno, sessionid, expiredtime 저장
                UserDefaults.standard.set(empno, forKey: "empno")
                UserDefaults.standard.set(sessionid, forKey: "sessionid")
                UserDefaults.standard.set(getExpiredTime(), forKey: "expiredTime")
                
                // token 구하기
                let delegate = UIApplication.shared.delegate as! AppDelegate
                token = delegate.myVariable
                print("token:", token!)
                
                // 푸시 알림 설정
                jsonDict = ["empno": empno, "sessionid": sessionid, "token": token]
                print("tokenResult:", postUrl(jsonDict: jsonDict, str: "setPushIDIOS"))
                
                self.loginResult = 9
            }
            else
            {
                self.loginResult = 4
            }
        }
        
        checkLoginResult()
    }
    
    // 로그인 버튼 클릭
    @IBAction func onLoginBtnClicked(_ sender: Any) {
        login()
    }
    
    // 세션 만료 시간 구하기
    func getExpiredTime() -> String! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let expiredTime = Date().addingTimeInterval(20 * 60) // 20분
        let expiredTimeStr = dateFormatter.string(from: expiredTime)
        
        print("expiredTime:", expiredTimeStr)
        
        return expiredTimeStr
    }
    
    func checkLoginResult() {
        print("loginResult:", loginResult)
        
        switch loginResult {
        case 1:
            self.showAlert(title: "로그인", msg: "사번을 입력하세요.")
            self.id.becomeFirstResponder()
        case 2:
            self.showAlert(title: "로그인", msg: "비밀번호를 입력하세요.")
            self.pw.becomeFirstResponder()
        case 3:
            self.showAlert(title: "로그인", msg: "사번을 확인하세요.")
            self.id.becomeFirstResponder()
        case 4:
            self.showAlert(title: "로그인", msg: "비밀번호를 확인하세요.")
            self.pw.becomeFirstResponder()
        case 9:
            let webViewController = self.storyboard?.instantiateViewController(withIdentifier: "WebViewController")
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.present(webViewController!, animated: true, completion: nil)
            }
        default:
            self.showAlert(title: "로그인", msg: "오류 발생! 다시 시도해 주세요.")
        }
    }
    
    func postUrl(jsonDict: Dictionary<String, String>, str: String) -> String {
        let url = URL(string: "https://mgate.seoul.co.kr/mobService/mobService.aspx/" + str)
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: [])
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.httpBody = jsonData
        
        var result: String!
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("error:", error)
                return
            }
            
            do {
                guard let data = data else { return }
                guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else { return }
                
                result = jsonResult["d"] as? String
                
                self.semaphore.signal()
            } catch {
                print("error:", error)
            }
        }
            
        task.resume()
        semaphore.wait()
        
        return result
    }
    
    func getMD5(_ string: String) -> String? {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = string.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes {
                (body: UnsafePointer<UInt8>) in CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }
        
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        // Move view 130 points upward
        self.view.frame.origin.y = -130
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        // Move view to original position
        self.view.frame.origin.y = 0
    }
}
