//
//  WebViewController.swift
//  mobilesis
//
//  Created by 서울신문사 on 2020/07/30.
//  Copyright © 2020 서울신문사. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var backBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(onResume), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let url = URL(string: "https://mgate.seoul.co.kr/mobsis/Home.aspx?start=1")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue(UserDefaults.standard.string(forKey: "empno")!, forHTTPHeaderField: "empno")
        request.addValue(UserDefaults.standard.string(forKey: "sessionid")!, forHTTPHeaderField: "sessionid")
        
        webView.load(request)
        
        print("--webView viewDidLoad")
    }
    
    @objc func onResume() {
        // 세션 만료 시간 체크
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let expiredTimeStr = UserDefaults.standard.string(forKey: "expiredTime")
        let expiredTime:Date = dateFormatter.date(from: expiredTimeStr!)!
        
        if Date() > expiredTime {
            showLoginAlert()
        }
        
        print("--webView onResume")
    }
    
    // 페이지 로드 시작
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        // 홈이면 뒤로가기 버튼 비활성화
        let url = webView.url!
        let urlStr = url.absoluteString
        
        backBtn.isEnabled = (urlStr.range(of: "Home.aspx") != nil) ? false : true
        
        print("--webView didStartProvisionalNavigation (" + urlStr + ")")
    }
    
    // 페이지 로드 종료
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        
        print("--webView didFinish")
    }
    
    // 외부 링크 열기
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let urlStr = url.description.lowercased()
        
        if url.scheme == "tel" || url.scheme == "mailto" || urlStr.range(of: "mgate.seoul.co.kr") == nil ||
            urlStr.hasSuffix(".zip") || urlStr.hasSuffix(".hwp") || urlStr.hasSuffix(".pdf") ||
            urlStr.hasSuffix(".doc") || urlStr.hasSuffix(".docx") || urlStr.hasSuffix(".xls") ||
            urlStr.hasSuffix(".xlsx") || urlStr.hasSuffix(".ppt") || urlStr.hasSuffix(".pptx") ||
            urlStr.hasSuffix(".mp3") || urlStr.hasSuffix(".mp4") || urlStr.hasSuffix(".jpg") {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            decisionHandler(.allow)
        }
        
        print("--webView decidePolicyFor (" + urlStr + ")")
    }
    
    // 뒤로가기 버튼 클릭
    @IBAction func onBackBtnClicked(_ sender: Any) {
        let url = webView.url!
        let urlStr = url.absoluteString
        
        if urlStr.range(of: "BoardDetail.aspx") != nil {
            let url = URL(string: urlStr.replacingOccurrences(of: "BoardDetail", with: "BoardList"))
            let request = URLRequest(url: url!)
            
            webView.load(request)
        }
        else if urlStr.range(of: "ApprList.aspx") != nil || urlStr.range(of: "ApprGongmun.aspx") != nil ||
            urlStr.range(of: "BoardList.aspx") != nil || urlStr.range(of: "Family.aspx") != nil ||
            urlStr.range(of: "MyunList.aspx") != nil || urlStr.range(of: "SMS.aspx") != nil ||
            urlStr.range(of: "Work.aspx") != nil || urlStr.range(of: "Settings.aspx") != nil {
            let url = URL(string:"https://mgate.seoul.co.kr/mobsis/Home.aspx")
            let request = URLRequest(url: url!)
            
            webView.load(request)
        }
        else {
            webView.goBack()
        }
    }
    
    // 홈 버튼 클릭
    @IBAction func onHomeBtnClicked(_ sender: Any) {
        let url = URL(string: "https://mgate.seoul.co.kr/mobsis/Home.aspx")
        let request = URLRequest(url: url!)
        
        webView.load(request)
    }
    
    // 로그아웃 버튼 클릭
    @IBAction func onLogoutBtnClicked(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // 페이지 확대/축소 비활성화
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func showLoginAlert() {
        let alertController = UIAlertController(title: "로그인", message: "세션이 만료되었습니다.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .cancel) { _ in
            self.presentingViewController?.dismiss(animated: true, completion: nil)
            print("--Session Expired")
        }
        
        alertController.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // 자바스크립트 확인창 1
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage msg: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .cancel) { _ in
            completionHandler()
        }
        
        alertController.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // 자바스크립트 확인창 2
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage msg: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
