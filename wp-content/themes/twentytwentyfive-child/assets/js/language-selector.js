/**
 * Language Selector for Front Page
 * - 브라우저 언어 자동 감지
 * - 언어 버튼 클릭 처리
 * - 카테고리 카드 클릭 시 언어별 이동
 */

(function() {
    'use strict';

    // 브라우저 언어 감지
    const browserLang = (navigator.language || navigator.userLanguage).startsWith('ko') ? 'ko' : 'en';

    // localStorage에서 저장된 언어 가져오기 (없으면 브라우저 언어)
    let selectedLang = localStorage.getItem('selectedLanguage') || browserLang;

    // 초기화
    function init() {
        updateUI(selectedLang);
        attachEventListeners();
    }

    // UI 업데이트
    function updateUI(lang) {
        // 버튼 상태 - 텍스트로 버튼 찾기
        const buttons = document.querySelectorAll('.language-selector-section .wp-block-button__link');
        let koBtn = null;
        let enBtn = null;

        buttons.forEach(btn => {
            if (btn.textContent.includes('한국어')) {
                koBtn = btn;
            } else if (btn.textContent.includes('English')) {
                enBtn = btn;
            }
        });

        if (koBtn && enBtn) {
            if (lang === 'ko') {
                koBtn.classList.add('active');
                enBtn.classList.remove('active');
            } else {
                koBtn.classList.remove('active');
                enBtn.classList.add('active');
            }
        }

        // 카드 설명
        const descKo = document.querySelectorAll('.desc-ko');
        const descEn = document.querySelectorAll('.desc-en');

        if (lang === 'ko') {
            descKo.forEach(el => el.style.display = 'inline');
            descEn.forEach(el => el.style.display = 'none');
        } else {
            descKo.forEach(el => el.style.display = 'none');
            descEn.forEach(el => el.style.display = 'inline');
        }
    }

    // 이벤트 리스너
    function attachEventListeners() {
        // 언어 버튼 클릭 - 텍스트로 버튼 찾기
        const buttons = document.querySelectorAll('.language-selector-section .wp-block-button__link');

        buttons.forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();

                if (this.textContent.includes('한국어')) {
                    selectedLang = 'ko';
                    localStorage.setItem('selectedLanguage', 'ko');
                    updateUI('ko');
                } else if (this.textContent.includes('English')) {
                    selectedLang = 'en';
                    localStorage.setItem('selectedLanguage', 'en');
                    updateUI('en');
                }
            });
        });

        // 카테고리 카드 클릭
        const cards = document.querySelectorAll('.category-card');
        cards.forEach(card => {
            card.addEventListener('click', function() {
                let category = '';

                if (this.classList.contains('category-book')) category = 'book';
                else if (this.classList.contains('category-web')) category = 'web';
                else if (this.classList.contains('category-youtube')) category = 'youtube';

                if (category) {
                    const slug = category + '-' + selectedLang;
                    const url = selectedLang === 'en'
                        ? `/en/category/${slug}/`
                        : `/category/${slug}/`;

                    window.location.href = url;
                }
            });
        });
    }

    // DOM 로드 완료 후 실행
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
