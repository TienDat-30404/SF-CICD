# Hướng dẫn xây dựng Salesforce CI/CD Pipeline với GitHub Actions

Tài liệu hướng dẫn thực hiện bài lab từ A đến Z để xây dựng pipeline CI/CD hoàn chỉnh cho 3 Org Salesforce miễn phí: **Dev → UAT → Prod**.

## Mục lục

1. [Tổng quan](#tổng-quan)
2. [Giai đoạn 1: Chuẩn bị 3 Org và môi trường Local](#giai-đoạn-1-chuẩn-bị-3-org-và-môi-trường-local)
3. [Giai đoạn 2: Tạo cặp key bảo mật (JWT Certificate)](#giai-đoạn-2-tạo-cặp-key-bảo-mật-jwt-certificate)
4. [Giai đoạn 3: Cấu hình Connected App trên cả 3 Org](#giai-đoạn-3-cấu-hình-connected-app-trên-cả-3-org)
5. [Giai đoạn 4: Cấu hình GitHub Repository và Secrets](#giai-đoạn-4-cấu-hình-github-repository-và-secrets)
6. [Giai đoạn 5: Khởi tạo Project và viết Workflow CI/CD](#giai-đoạn-5-khởi-tạo-project-và-viết-workflow-cicd)
7. [Kiểm thử luồng CI/CD](#kiểm-thử-luồng-cicd)

---

## Tổng quan

### Mục tiêu

Tự động validate và deploy code Salesforce qua các môi trường khi có Pull Request / Merge trên GitHub.

### Luồng triển khai

```
dev  ──PR──▶  uat  ──PR──▶  main
 │             │              │
Dev Org     UAT Org        Prod Org
```

| Nhánh  | Org tương ứng | Khi mở Pull Request | Khi Merge (push)  |
| ------ | ------------- | ------------------- | ----------------- |
| `dev`  | Dev           | –                   | –                 |
| `uat`  | UAT           | Validate lên UAT    | Deploy lên UAT    |
| `main` | Prod          | Validate lên Prod   | Deploy lên Prod   |

### Lộ trình 5 giai đoạn

1. Chuẩn bị 3 Org và môi trường Local
2. Tạo cặp key bảo mật (JWT Certificate)
3. Cấu hình Connected App trên 3 Org
4. Tạo GitHub Repo và đưa key vào Secrets
5. Viết Workflow và chạy thử CI/CD

---

## Giai đoạn 1: Chuẩn bị 3 Org và môi trường Local

### 1.1. Đăng ký 3 Developer Edition Org

Đăng ký tại [developer.salesforce.com/signup](https://developer.salesforce.com/signup):

| Org   | Mục đích    | Username (ví dụ)       |
| ----- | ----------- | ---------------------- |
| Org 1 | Dev         | `test1@demo.com`   |
| Org 2 | UAT         | `test2@demo.com`   |
| Org 3 | Production  | `test3@demo.com`  |

### 1.2. Kiểm tra công cụ trên máy Local

Mở Terminal (macOS/Linux) hoặc PowerShell / Command Prompt (Windows) và chạy:

```bash
# 1. Kiểm tra Git
git --version

# 2. Kiểm tra Salesforce CLI
sf --version

# 3. Kiểm tra OpenSSL (dùng để tạo key ở Giai đoạn 2)
openssl version
```

---

## Giai đoạn 2: Tạo cặp key bảo mật (JWT Certificate)

GitHub Actions cần một cặp key để tự động đăng nhập vào Salesforce mà không cần nhập password.

Mở Terminal (hoặc Git Bash) và chạy lần lượt:

```bash
# 1. Tạo Private Key
openssl genrsa -out server.key 2048

# 2. Tạo Certificate tự ký (Public Key)
openssl req -new -x509 -key server.key -out server.crt -days 3650 -subj "/CN=SalesforceDemo"
```

Kết quả thu được 2 file trong thư mục hiện tại:

| File         | Vai trò                                                   |
| ------------ | --------------------------------------------------------- |
| `server.key` | Private key. **Giữ bí mật**, sẽ đưa vào GitHub Secrets.  |
| `server.crt` | Certificate. Upload lên Salesforce Connected App.         |

> **Cảnh báo:** Không commit `server.key` lên Git. Hãy thêm `server.key` vào `.gitignore`.

---

## Giai đoạn 3: Cấu hình Connected App trên cả 3 Org

Thực hiện các bước dưới đây **trên cả 3 Org (Dev, UAT, Prod)**.

### 3.1. Tạo Connected App

1. Đăng nhập vào Org → chọn **Setup** (biểu tượng bánh răng) → tìm **App Manager** ở ô Quick Find.
2. Bấm **New Connected App** (góc trên bên phải) và điền:
   - **Connected App Name:** `GitHub CI CD`
   - **API Name:** `GitHub_CI_CD`
   - **Contact Email:** email của bạn
3. Tích chọn **Enable OAuth Settings**.
4. **Callback URL:** `http://localhost:1717/OauthRedirect`
5. Tích chọn **Enable JWT Bearer Flow** → bấm **Choose File** và chọn file `server.crt` đã tạo ở Giai đoạn 2.
6. Tại mục **Selected OAuth Scopes**, chuyển 3 dòng sau sang cột bên phải:
   - Manage user data via APIs (`api`)
   - Manage user data via Web browsers (`web`)
   - Perform requests at any time (`refresh_token`, `offline_access`)
7. Bấm **Save** → **Continue**.

### 3.2. Lấy Consumer Key

Tại Tab Setting -> Oauth Settings, bấm **Consumer Key and Secret**  → copy **Consumer Key** và lưu lại (ví dụ ra Notepad). Mỗi Org sẽ có một Consumer Key riêng.

### 3.3. Cấu hình chính sách truy cập

1. Bấm **Manage** ở trên cùng → bấm **Edit Policies**.
2. Tại mục **Permitted Users**, chọn **Admin approved users are pre-authorized**.
3. Bấm **Save**.
4. Cuộn xuống phần **Profiles** (ở trang Manage) → bấm **Manage Profiles** → tích chọn profile **System Administrator** → bấm **Save**.

---

## Giai đoạn 4: Cấu hình GitHub Repository và Secrets

### 4.1. Tạo GitHub Repository

Truy cập [github.com](https://github.com) → tạo Repository mới tên `salesforce-cicd-demo` (Public hoặc Private đều được).

### 4.2. Thêm Secrets

Vào Repo vừa tạo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**, thêm các biến sau:

| Tên Secret            | Giá trị                                                                                                                      |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `SF_JWT_SECRET_KEY`   | Toàn bộ nội dung file `server.key` (từ `-----BEGIN RSA PRIVATE KEY-----` đến hết), mở bằng Notepad/TextEdit rồi copy và dán. |
| `SF_DEV_CONSUMER_KEY` | Consumer Key của Connected App trên Org Dev.                                                                                 |
| `SF_DEV_USERNAME`     | Username của Org Dev (ví dụ `test1@demo.com`).                                                                           |
| `SF_UAT_CONSUMER_KEY` | Consumer Key của Connected App trên Org UAT.                                                                                 |
| `SF_UAT_USERNAME`     | Username của Org UAT (ví dụ `test2@demo.com`).                                                                           |
| `SF_PROD_CONSUMER_KEY`| Consumer Key của Connected App trên Org Prod.                                                                                |
| `SF_PROD_USERNAME`    | Username của Org Prod (ví dụ `test3@demo.com`).                                                                         |

---

## Giai đoạn 5: Khởi tạo Project và viết Workflow CI/CD

### 5.1. Khởi tạo Salesforce Project trên máy Local

```bash
# Tạo Salesforce Project
sf project generate --name sf-cicd-demo
cd sf-cicd-demo

# Khởi tạo Git Repo và link với GitHub
git init
git branch -M main
git remote add origin <URL_GITHUB_REPO_CỦA_BẠN.git>
```

### 5.2. Tạo file pipeline GitHub Actions

Tạo thư mục `.github/workflows` trong project, sau đó tạo file `deploy.yml`:

```yaml
name: Salesforce Multi-Org CI/CD Pipeline

on:
  push:
    branches: [ uat, main ]
  pull_request:
    branches: [ uat, main ]

jobs:
  # ==========================================
  # JOB 1: VALIDATE & DEPLOY TO UAT
  # ==========================================
  uat-deployment:
    if: github.ref == 'refs/heads/uat' || github.base_ref == 'uat'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate to UAT Org
        run: |
          echo "${{ secrets.SF_JWT_SECRET_KEY }}" > server.key
          sf org login jwt --client-id ${{ secrets.SF_UAT_CONSUMER_KEY }} --jwt-key-file server.key --username ${{ secrets.SF_UAT_USERNAME }} --alias uatOrg --instance-url https://login.salesforce.com
          rm server.key

      # Validate khi mở PR vào UAT
      - name: Validate Deployment (Pull Request)
        if: github.event_name == 'pull_request'
        run: |
          sf project deploy validate --target-org uatOrg --source-dir force-app --test-level RunLocalTests

      # Deploy thật khi Merge PR vào UAT
      - name: Deploy Source (Push/Merge)
        if: github.event_name == 'push'
        run: |
          sf project deploy start --target-org uatOrg --source-dir force-app --test-level RunLocalTests

  # ==========================================
  # JOB 2: VALIDATE & DEPLOY TO PROD
  # ==========================================
  prod-deployment:
    if: github.ref == 'refs/heads/main' || github.base_ref == 'main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate to PROD Org
        run: |
          echo "${{ secrets.SF_JWT_SECRET_KEY }}" > server.key
          sf org login jwt --client-id ${{ secrets.SF_PROD_CONSUMER_KEY }} --jwt-key-file server.key --username ${{ secrets.SF_PROD_USERNAME }} --alias prodOrg --instance-url https://login.salesforce.com
          rm server.key

      # Validate khi mở PR vào Main (Prod)
      - name: Validate Deployment (Pull Request)
        if: github.event_name == 'pull_request'
        run: |
          sf project deploy validate --target-org prodOrg --source-dir force-app --test-level RunLocalTests

      # Deploy thật khi Merge PR vào Main (Prod)
      - name: Deploy Source (Push/Merge)
        if: github.event_name == 'push'
        run: |
          sf project deploy start --target-org prodOrg --source-dir force-app --test-level RunLocalTests
```

### 5.3. Push code và khởi tạo các nhánh

```bash
# Push code ban đầu lên main
git add .
git commit -m "ci: setup github actions pipeline"
git push -u origin main

# Tạo nhánh uat và dev
git checkout -b uat
git push -u origin uat

git checkout -b dev
git push -u origin dev
```

---

## Kiểm thử luồng CI/CD

### Bước 1: Thay đổi code trên máy Local

Đang ở nhánh `dev`, tạo một Custom Field hoặc một Apex Class mới trong thư mục `force-app`, sau đó push lên nhánh `dev`:

```bash
git add .
git commit -m "feat: add new custom field"
git push origin dev
```

### Bước 2: Deploy lên UAT

1. Trên GitHub, mở Pull Request từ `dev` → `uat`.
2. Vào tab **Actions**, pipeline sẽ chạy bước **Validate** trên UAT.
3. Khi Validate thành công, bấm **Merge Pull Request**. Pipeline tự chạy bước **Deploy to UAT**.

### Bước 3: Deploy lên Production

1. Mở Pull Request từ `uat` → `main`.
2. Pipeline thực hiện tương tự: Validate khi mở PR, Deploy lên Prod khi Merge.

---

## Xử lý sự cố thường gặp

| Lỗi                                      | Nguyên nhân / Cách xử lý                                                                                  |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `openssl` không nhận diện (Windows)      | Dùng Git Bash thay cho PowerShell.                                                                        |
| `user hasn't approved this consumer`     | Kiểm tra **Permitted Users** = *Admin approved users are pre-authorized* và đã gán profile System Admin.  |
| Lỗi đăng nhập JWT                        | Kiểm tra `SF_JWT_SECRET_KEY` đã dán đủ nội dung key, và Consumer Key / Username đúng với từng Org.        |
| `unknown flag --no-prompt`               | Lệnh `sf project deploy start` không có cờ `--no-prompt`, hãy xoá cờ này khỏi workflow.                   |
