/**
 * Language Selector Script
 * - 브라우저 언어 자동 감지
 * - localStorage에 선택 언어 저장
 * - 언어 버튼 상태 관리
 * - 카테고리 카드 클릭 시 언어별 URL로 이동
 */

window.addEventListener('load', function() {
    // 1. 저장된 언어 또는 브라우저 언어 감지
    let selectedLang = localStorage.getItem('selectedLanguage');

    if (!selectedLang) {
        // 브라우저 언어 감지
        const browserLang = navigator.language || navigator.userLanguage;
        selectedLang = browserLang.startsWith('ko') ? 'ko' : 'en';
    }

    // 2. 초기 UI 업데이트
    updateUI(selectedLang);

    function updateUI(lang) {
        // 버튼 상태 업데이트
        document.querySelectorAll('.lang-btn').forEach(btn => {
            if (btn.dataset.lang === lang) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });

        // 라벨 텍스트 변경
        const label = document.querySelector('.language-label');
        if (label) {
            label.textContent = lang === 'en' ? 'Select Language:' : '언어 선택:';
        }

        // 카드 설명 텍스트 변경
        document.querySelectorAll('.category-card').forEach(card => {
            const koDesc = card.querySelector('.card-desc-ko');
            const enDesc = card.querySelector('.card-desc-en');

            if (lang === 'en') {
                if (koDesc) koDesc.style.display = 'none';
                if (enDesc) enDesc.style.display = 'block';
            } else {
                if (koDesc) koDesc.style.display = 'block';
                if (enDesc) enDesc.style.display = 'none';
            }
        });
    }

    // 3. 언어 선택 버튼 클릭 이벤트
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            const lang = this.dataset.lang;

            // localStorage에 저장
            localStorage.setItem('selectedLanguage', lang);
            selectedLang = lang;

            // UI 업데이트
            updateUI(lang);
        });
    });

    // 4. 카테고리 카드 클릭 이벤트
    document.querySelectorAll('.category-card').forEach(card => {
        card.addEventListener('click', function(e) {
            e.preventDefault();
            const categoryBase = this.dataset.category;
            const baseUrl = window.location.origin;

            // 카테고리 slug 규칙: 범주명-ko (한국어), 범주명-en (영어)
            let categorySlug;
            if (selectedLang === 'en') {
                categorySlug = categoryBase + '-en';
            } else {
                categorySlug = categoryBase + '-ko';
            }

            // URL 구성
            let url;
            if (selectedLang === 'en') {
                url = baseUrl + '/en/category/' + categorySlug + '/';
            } else {
                url = baseUrl + '/category/' + categorySlug + '/';
            }

            window.location.href = url;
        });
    });
});
