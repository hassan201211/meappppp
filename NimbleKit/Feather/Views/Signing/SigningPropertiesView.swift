//
//  SigningAppPropertiesView.swift
//  Feather
//
//  Created by samara on 17.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SigningPropertiesView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var text: String = ""
    
    var saveButtonDisabled: Bool {
        text == initialValue || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var title: String
    var initialValue: String 
    @Binding var bindingValue: String?
    
    // MARK: Body
    var body: some View {
        NBList(title) {
            Section {
                // بطاقة إدخال النص الاحترافية
                HStack(spacing: 12) {
                    // أيقونة الحقل الجانبية
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    // حقل الإدخال وزر الحذف السريع
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            TextField(title, text: $text)
                                .font(.system(size: 16, weight: .regular))
                                .textInputAutocapitalization(.none)
                                .autocorrectionDisabled(true)
                            
                            // إظهار زر المسح فقط عند وجود نص لتسهيل التعديل
                            if !text.isEmpty {
                                Button(action: {
                                    withAnimation(.snappy) { text = "" }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(.systemGray3))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } footer: {
                // عرض القيمة الأصلية كمرجع للمستخدم إذا قام بالتعديل
                if text != initialValue {
                    Text("القيمة الأصلية: \(initialValue)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        .transition(.opacity)
                }
            }
        }
        .toolbar {
            NBToolbarButton(
                .localized("Save"),
                style: .text,
                placement: .topBarTrailing,
                isDisabled: saveButtonDisabled
            ) {
                if !saveButtonDisabled {
                    // حفظ النص بعد تنظيف المسافات الزائدة
                    bindingValue = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismiss()
                }
            }
        }
        .onAppear {
            text = initialValue
        }
    }
}
