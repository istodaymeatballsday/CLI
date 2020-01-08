#!/usr/bin/python
# -*- coding: utf-8 -*-

from datetime import datetime
from datetime import timedelta
from threading import Thread
from Queue import Queue
import xml.etree.ElementTree as ET
import locale
import urllib2
import json
import sys
import re

restaurants = [["Expressen", '3d519481-1667-4cad-d2a3'],
               ["Kårrestaurangen", '21f31565-5c2b-4b47-d2a1'],
               ["Linsen", 'b672efaf-032a-4bb8-d2a5'],
               ["S.M.A.K", '3ac68e11-bcee-425e-d2a8'],
               ["J.A. Pripps", 'http://intern.chalmerskonferens.se/'
                'view/restaurant/j-a-pripps-pub-cafe/RSS%20Feed.rss']]


def main():
    set_locale("sv_SE.utf-8")
    num_of_restaurants = len(restaurants)
    num_of_days = get_param()

    queue = build_queue(restaurants, num_of_days, num_of_restaurants)
    menus = get_menus(queue)

    print_data(menus)


def get_menus(queue):
    menus = {}
    for i in range(queue.qsize()):
        thread = Thread(target=get_data_thread,
                        args=(queue, menus))
        thread.daemon = True
        thread.start()

    queue.join()

    return menus


def build_queue(restaurants, num_of_days, num_of_restaurants):
    queue = Queue()
    for restaurant in range(num_of_restaurants):
        queue.put((num_of_days, restaurant, num_of_restaurants))

    return queue


def get_data_thread(queue, menus):
    while not queue.empty():
        q = queue.get()

        if q[1] == 4:
            menu = get_pripps_data(q[1], q[0])
        else:
            menu = get_data(q[1], q[0])

        map_data(menus, menu, q[1], q[2])
        queue.task_done()


def get_data(restaurant, num_of_days):
    start_date, end_date = get_dates(num_of_days)
    url = api.API_URL(
        restaurants[restaurant][1],
        start_date,
        end_date)

    try:
        res = urllib2.urlopen(url).read()

    except urllib2.HTTPError as e:
        print "HTTPError: {}, {}".format(e.code, e.reason)

    except urllib2.HTTPException as e:
        print "HTTPException: {}".format(e)

    except Exception as e:
        print "Exception: {}".format(e)

    rawdata = json.loads(res)
    data = []
    for i in rawdata:
        data.append(format_date(i['startDate']))
        data.append(i['displayNames'][0]['dishDisplayName'])

    return data


def get_pripps_data(restaurant, num_of_days):
    data = []
    item = parse_xml(restaurant)
    start_date, end_date = get_dates(num_of_days)

    for title in item:
        date = title.find("title").text[-10:]

        for description in title:
            for table in description:
                for tr in table:
                    for td in tr:
                        dish = tr.findall("td")[1].text

                        for b in td:
                            dish_type = b.text

                            if date_in_range(date,
                                             start_date,
                                             end_date):
                                append_data(data,
                                            date,
                                            dish,
                                            dish_type)
    return data


def append_data(data, date, dish, dish_type):
    data.append(date)
    data.append(dish + style.DIM +
                " (" + dish_type + ")" + style.DEFAULT)


def parse_xml(restaurant):
    root = ET.fromstring(
        urllib2.urlopen(restaurants[restaurant][1]).read())

    return root.findall('channel/item')


def date_in_range(date, start_date, end_date):
    return start_date <= date <= end_date


def map_data(menus, data, restaurant, num_of_restaurants):
    length = len(data)
    for i in range(0, length, 2):

        date = data[i]
        dish = data[i+1]

        if date in menus:
            menus[date][restaurant].append(dish)
        else:
            disharr = [[] for i in range(num_of_restaurants)]
            disharr[restaurant].append(dish)
            menus[date] = disharr


def print_data(menus):
    if not menus:
        print "Ingen data"
        quit()

    for key in sorted(menus):
        print
        print_date(key)

        for restaurant, menu in enumerate(menus[key]):
            print_restaurant(menu, restaurant)

            for dish in menu:
                print_element(dish)
    print


def get_param():
    try:
        param = sys.argv[1:][0]
        if is_int(param):
            if 0 <= param:
                return int(param)
        return 0
    except IndexError:
        return 0


def is_int(param):
    try:
        int(param)
        return True
    except ValueError:
        return False


def find_index(reg):
    try:
        index = reg.start()
        return index
    except AttributeError:
        return -1


def get_dates(num_of_days):
    today = datetime.today()
    end_date = (today + timedelta(days=num_of_days)).strftime('%Y-%m-%d')
    start_date = today.strftime('%Y-%m-%d')
    return start_date, end_date


def format_date(date):
    return datetime.strptime(
        date[:-3], '%m/%d/%Y %H:%M:%S').strftime('%Y-%m-%d')


def print_date(date):
    print style.BOLD + style.GREEN + datetime.strptime(
        date, '%Y-%m-%d').strftime('%a') + style.DEFAULT


def print_element(dish):
    ingredient = "köttbullar".decode("utf-8")
    ans = re.search(r'\b' + re.escape(ingredient)
                    + r'\b', dish, re.IGNORECASE)

    index = find_index(ans)
    if index != -1:
        print_match(dish, ingredient, index)
    else:
        print style.DOT + dish


def print_match(dish, ingredient, index):
    length = (index+len(ingredient))

    head = dish[0:index]
    body = dish[index:length]
    tail = dish[length:]

    print style.DOT + head + style.BLINK + \
        body + style.DEFAULT + tail


def print_restaurant(menu, restaurant):
    print style.BLUE + restaurants[restaurant][0] + style.DEFAULT
    if not menu:
        print style.DOT + style.DIM + "Ingen meny" + style.DEFAULT


def set_locale(code):
    locale.setlocale(locale.LC_ALL, code)


class api:
    BASE_URL = \
        'http://carbonateapiprod.azurewebsites.net/' \
        'api/v1/mealprovidingunits/'

    @staticmethod
    def API_URL(restaurant, start_date, end_date):
        return api.BASE_URL + restaurant + \
            '-08d558129279/dishoccurrences?' \
            'startDate=' + start_date + \
            '&endDate=' + end_date


class style:
    DEFAULT = '\033[0m'
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    BOLD = "\033[1m"
    BLINK = '\33[5m'
    DIM = '\033[2m'
    DOT = "· ".decode("utf-8")


if __name__ == "__main__":
    main()
