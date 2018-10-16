//
//  ViewController.swift
//  P2HAKCS
//
//  Created by 横山新 on 2018/10/16.
//  Copyright © 2018年 横山新. All rights reserved.
//

import UIKit
import Firebase

// enumやstructを使うか否か．．．
enum textFieldKind:Int {
    case name = 1
    case message = 2
    case id = 3
}

enum Mode {
    case add
    case edit
    case delete
}

struct messageData: Codable {
    let name: String
    let message: String
    let id: String
}

class ViewController: UIViewController {
    
    //Firestoreへのコネクションを張る
    var ref: Firestore!
    // 初期値は追加
    var mode: Mode = .add
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var idTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // UI部品のセットアップ
        messageTextField.delegate = self
        nameTextField.delegate = self
        idTextField.delegate = self
        messageTextField.tag = textFieldKind.message.rawValue
        nameTextField.tag = textFieldKind.name.rawValue
        idTextField.tag = textFieldKind.id.rawValue
        
        //Firestoreへのコネクションを張る
        ref = Firestore.firestore()
        
        //Firestoreからデータを取得し、TextViewに表示する
        ref.collection("chat").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.textView.text = ""
            for item in documents {
                let chatDataOp = item.data() as? Dictionary<String, String>
                guard let chatData = chatDataOp else {
                    return
                }
                guard let message = chatData["message"] else {
                    return
                }
                guard let name = chatData["name"] else {
                    return
                }
                guard let id = chatData["id"] else {
                    return
                }
                //TextViewの一番下に新しいメッセージ内容を追加する
                self.textView.text =  "\(self.textView.text!)\nID : \(id) : \(name) : \(message)"
            }
        }
    }
    
    @IBAction func changeModeAdd(_ sender: Any) {
        mode = .add
        modeLabel.text = "Mode : add"
    }
    @IBAction func changeModeEdit(_ sender: Any) {
        mode = .edit
        modeLabel.text = "Mode : edit"
    }
    @IBAction func changeModeDelete(_ sender: Any) {
        mode = .delete
        modeLabel.text = "Mode : delete"
    }
    
}

extension ViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // documentを特定するためのidをランダムで生成　もっと素敵なやり方がありそう
        let id = String(Int.random(in: 0 ... 100))
        
        //キーボードを閉じる
        textField.resignFirstResponder()
        
        //入力された値を格納 コードが複雑になるので，空文字も許容にする．．．？
        let messagedata = messageData(name: nameTextField.text ?? "", message: messageTextField.text ?? "", id: id)
        
        //Firestoreに送信する
        sendData(messagedata: messagedata)
        
        //メッセージの中身を空にする
        messageTextField.text = ""
        
        // idTextFieldを空にする
        idTextField.text = ""
        
        return true
    }
    
    func sendData(messagedata: messageData) -> Void {
        switch mode {
        case .add:
            ref.collection("chat").document(messagedata.id).setData(["name":messagedata.name, "message":messagedata.message, "id":messagedata.id])
        case .edit:
            //idTextFieldに入力されたテキストを変数に入れる。nilの場合はFirestoreへ行く処理をしない
            guard let targetId = idTextField.text else {
                return
            }
            ref.collection("chat").document(targetId).updateData(["message":messagedata.message])
        case .delete:
            //idTextFieldに入力されたテキストを変数に入れる。nilの場合はFirestoreへ行く処理をしない
            guard let targetId = idTextField.text else {
                return
            }
            ref.collection("chat").document(targetId).delete()
        }
    }
}
